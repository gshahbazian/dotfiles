import { isIP } from "node:net"
import { lookup } from "node:dns/promises"
import { Readability } from "@mozilla/readability"
import { parseHTML } from "linkedom"
import TurndownService from "turndown"

// Simplified content fetching: web pages -> markdown, with an SSRF guard.

export interface ExtractedContent {
  url: string
  title: string
  content: string
  error?: string
}

const FETCH_TIMEOUT_MS = 30_000
const MAX_CONTENT_BYTES = 10 * 1024 * 1024
const MAX_STORED_CHARS = 500_000
const MIN_USEFUL_CONTENT = 200

const turndown = new TurndownService({
  headingStyle: "atx",
  codeBlockStyle: "fenced",
})

function ipv4IsPrivate(ip: string): boolean {
  const parts = ip.split(".").map(Number)
  if (
    parts.length !== 4 ||
    parts.some((n) => !Number.isInteger(n) || n < 0 || n > 255)
  ) {
    return true
  }
  const [a, b] = parts as [number, number, number, number]
  if (a === 0 || a === 127) return true // "this host" / loopback
  if (a === 10) return true // private
  if (a === 172 && b >= 16 && b <= 31) return true // private
  if (a === 192 && b === 168) return true // private
  if (a === 169 && b === 254) return true // link-local (incl. cloud metadata)
  if (a === 100 && b >= 64 && b <= 127) return true // CGNAT
  if (a >= 224) return true // multicast / reserved
  return false
}

function ipv6IsPrivate(ip: string): boolean {
  const s = ip.toLowerCase().split("%")[0] ?? ""
  if (s === "::1" || s === "::") return true // loopback / unspecified
  if (s.startsWith("fe80")) return true // link-local
  if (s.startsWith("fc") || s.startsWith("fd")) return true // unique local
  const mapped = s.match(/::ffff:(\d+\.\d+\.\d+\.\d+)$/)
  if (mapped?.[1]) return ipv4IsPrivate(mapped[1])
  return false
}

// Reject anything that isn't a public http(s) host. Best-effort: we validate the
// requested host and (after the fetch) the final redirected URL, but do not
// re-check every intermediate redirect hop.
async function assertPublicUrl(rawUrl: string): Promise<URL> {
  let url: URL
  try {
    url = new URL(rawUrl)
  } catch {
    throw new Error(`Invalid URL: ${rawUrl}`)
  }
  if (url.protocol !== "http:" && url.protocol !== "https:") {
    throw new Error(`Unsupported protocol: ${url.protocol}`)
  }
  const host = url.hostname.replace(/^\[|\]$/g, "")
  const kind = isIP(host)
  if (kind === 4) {
    if (ipv4IsPrivate(host)) {
      throw new Error(`Refusing to fetch private address: ${host}`)
    }
    return url
  }
  if (kind === 6) {
    if (ipv6IsPrivate(host)) {
      throw new Error(`Refusing to fetch private address: ${host}`)
    }
    return url
  }
  if (host === "localhost" || host.endsWith(".localhost")) {
    throw new Error(`Refusing to fetch localhost`)
  }
  const addrs = await lookup(host, { all: true })
  for (const { address, family } of addrs) {
    const priv = family === 4 ? ipv4IsPrivate(address) : ipv6IsPrivate(address)
    if (priv) {
      throw new Error(
        `Refusing to fetch ${host} — resolves to private address ${address}`,
      )
    }
  }
  return url
}

function htmlToMarkdown(
  html: string,
  fallbackUrl: string,
): { title: string; content: string } {
  // linkedom + Readability aren't typed against this project's DOM-less tsconfig,
  // so we cross the boundary with `any` casts.
  let title = fallbackUrl
  let bodyHtml = html
  try {
    const { document } = parseHTML(html)
    const article = new Readability(document as any).parse()
    if (article) {
      if (article.title?.trim()) title = article.title.trim()
      if (article.content) bodyHtml = article.content
      let md = turndown.turndown(bodyHtml)
      if (
        (!md || md.trim().length < MIN_USEFUL_CONTENT) &&
        article.textContent
      ) {
        md = article.textContent
      }
      return { title, content: md.trim() }
    }
    const docBody = (document as any).body?.innerHTML
    if (typeof docBody === "string" && docBody.length > 0) bodyHtml = docBody
  } catch {
    // Fall back to converting the raw HTML.
  }
  return { title, content: turndown.turndown(bodyHtml).trim() }
}

export async function fetchAndExtract(
  rawUrl: string,
  signal?: AbortSignal,
): Promise<ExtractedContent> {
  const url = await assertPublicUrl(rawUrl)
  const timeout = AbortSignal.timeout(FETCH_TIMEOUT_MS)
  const combined = signal ? AbortSignal.any([timeout, signal]) : timeout

  const response = await fetch(url, {
    headers: {
      "User-Agent":
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36",
      Accept: "text/html,application/xhtml+xml,text/plain;q=0.9,*/*;q=0.8",
    },
    redirect: "follow",
    signal: combined,
  })

  // Re-validate the final URL after any redirects.
  await assertPublicUrl(response.url || rawUrl)

  if (!response.ok) {
    throw new Error(`HTTP ${response.status} ${response.statusText}`)
  }

  const contentType = (response.headers.get("content-type") ?? "").toLowerCase()
  const isText =
    contentType.includes("text/html") ||
    contentType.includes("application/xhtml") ||
    contentType.includes("text/plain") ||
    contentType.includes("xml") ||
    contentType === ""
  if (!isText) {
    throw new Error(`Unsupported content type: ${contentType || "unknown"}`)
  }

  const lengthHeader = Number(response.headers.get("content-length"))
  if (Number.isFinite(lengthHeader) && lengthHeader > MAX_CONTENT_BYTES) {
    throw new Error(`Response too large: ${lengthHeader} bytes`)
  }

  let html = await response.text()
  if (html.length > MAX_CONTENT_BYTES) html = html.slice(0, MAX_CONTENT_BYTES)

  const finalUrl = response.url || rawUrl
  const isPlain = contentType.includes("text/plain")
  const { title, content } = isPlain
    ? { title: finalUrl, content: html.trim() }
    : htmlToMarkdown(html, finalUrl)

  const trimmed =
    content.length > MAX_STORED_CHARS
      ? content.slice(0, MAX_STORED_CHARS)
      : content

  return { url: finalUrl, title, content: trimmed }
}

// A tiny concurrency limiter so multi-URL fetches don't stampede.
export async function mapWithConcurrency<T, R>(
  items: T[],
  limit: number,
  fn: (item: T, index: number) => Promise<R>,
): Promise<R[]> {
  const results: R[] = new Array(items.length)
  let next = 0
  const workers = Array.from(
    { length: Math.min(limit, items.length) },
    async () => {
      while (true) {
        const index = next++
        if (index >= items.length) break
        results[index] = await fn(items[index]!, index)
      }
    },
  )
  await Promise.all(workers)
  return results
}
