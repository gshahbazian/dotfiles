import { isIP } from "node:net"
import { lookup } from "node:dns/promises"
import { Readability } from "@mozilla/readability"
import { parseHTML } from "linkedom"
import TurndownService from "turndown"

// Web pages -> markdown, with an SSRF guard.

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
const MAX_REDIRECTS = 5

const FETCH_HEADERS = {
  "User-Agent":
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36",
  Accept: "text/html,application/xhtml+xml,text/plain;q=0.9,*/*;q=0.8",
}

const turndown = new TurndownService({
  headingStyle: "atx",
  codeBlockStyle: "fenced",
})

function ipv4IsPrivate(ip: string): boolean {
  const parts = ip.split(".").map(Number)
  if (
    parts.length !== 4 ||
    parts.some((n) => !Number.isInteger(n) || n > 255)
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

// Expand an IPv6 literal into its eight 16-bit hextets. Returns null when it
// can't be parsed — callers treat that as private (fail closed).
function expandIpv6(ip: string): number[] | null {
  let s = ip.toLowerCase().split("%")[0] ?? ""

  // Fold a trailing dotted-quad (::ffff:1.2.3.4) into two hextets.
  const dotted = /^(.*:)(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/.exec(s)
  if (dotted) {
    const octets = dotted.slice(2).map(Number)
    if (octets.some((n) => n > 255)) return null
    const hi = ((octets[0]! << 8) | octets[1]!).toString(16)
    const lo = ((octets[2]! << 8) | octets[3]!).toString(16)
    s = `${dotted[1]}${hi}:${lo}`
  }

  const parts = s.split("::")
  if (parts.length > 2) return null

  const head = parts[0] ? parts[0].split(":") : []
  const tail = parts.length === 2 ? (parts[1] ? parts[1].split(":") : []) : null

  let groups = head
  if (tail !== null) {
    const missing = 8 - head.length - tail.length
    if (missing < 0) return null
    groups = [...head, ...Array(missing).fill("0"), ...tail]
  }
  if (groups.length !== 8) return null

  const nums = groups.map((g) =>
    /^[0-9a-f]{1,4}$/.test(g) ? parseInt(g, 16) : NaN,
  )
  if (nums.some(Number.isNaN)) return null
  return nums
}

function ipv6IsPrivate(ip: string): boolean {
  const g = expandIpv6(ip)
  if (!g) return true // unparseable — fail closed
  if (g.every((h) => h === 0)) return true // :: unspecified
  if (g.slice(0, 7).every((h) => h === 0) && g[7] === 1) return true // ::1
  if ((g[0]! & 0xffc0) === 0xfe80) return true // fe80::/10 link-local
  if ((g[0]! & 0xfe00) === 0xfc00) return true // fc00::/7 unique local

  // IPv4-mapped (::ffff:0:0/96) or IPv4-compatible (::/96): the embedded
  // IPv4 governs. Covers the hex-hextet form too (e.g. ::ffff:7f00:1).
  if (g.slice(0, 5).every((h) => h === 0) && (g[5] === 0 || g[5] === 0xffff)) {
    const v4 = `${g[6]! >> 8}.${g[6]! & 0xff}.${g[7]! >> 8}.${g[7]! & 0xff}`
    return ipv4IsPrivate(v4)
  }
  return false
}

// Reject anything that isn't a public http(s) host. Called on the initial URL
// and on every redirect target before it is requested. Best-effort: a DNS-
// rebinding host can still resolve differently between this check and the
// actual connect.
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
  if (kind !== 0) {
    const priv = kind === 4 ? ipv4IsPrivate(host) : ipv6IsPrivate(host)
    if (priv) throw new Error(`Refusing to fetch private address: ${host}`)
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
  // linkedom + Readability aren't typed against this DOM-less tsconfig, so we
  // cross the boundary with `any` casts.
  let title = fallbackUrl
  let bodyHtml = html
  try {
    const { document } = parseHTML(html)
    const article = new Readability(document as any).parse()
    if (article) {
      if (article.title?.trim()) title = article.title.trim()
      if (article.content) bodyHtml = article.content

      let md = turndown.turndown(bodyHtml)
      if (md.trim().length < MIN_USEFUL_CONTENT && article.textContent) {
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

// Follow redirects manually so every hop is validated *before* we request it —
// `redirect: "follow"` would fire the request at a private redirect target
// before we could check it.
async function fetchGuarded(url: URL, signal: AbortSignal): Promise<Response> {
  let current = url
  for (let hop = 0; hop <= MAX_REDIRECTS; hop++) {
    const response = await fetch(current, {
      headers: FETCH_HEADERS,
      redirect: "manual",
      signal,
    })

    const location = response.headers.get("location")
    if (response.status >= 300 && response.status < 400 && location) {
      const next = new URL(location, current)
      await assertPublicUrl(next.toString())
      current = next
      continue
    }
    return response
  }
  throw new Error(`Too many redirects (>${MAX_REDIRECTS})`)
}

// Read the body enforcing the byte cap as bytes stream in, so a server that
// omits (or lies about) Content-Length can't buffer an unbounded response.
async function readCappedBody(
  response: Response,
  maxBytes: number,
): Promise<string> {
  if (!response.body) return ""

  const reader = response.body.getReader()
  const chunks: Uint8Array[] = []
  let total = 0
  try {
    while (total < maxBytes) {
      const { done, value } = await reader.read()
      if (done) break
      if (value) {
        chunks.push(value)
        total += value.byteLength
      }
    }
  } finally {
    await reader.cancel().catch(() => {})
  }
  return Buffer.concat(chunks).subarray(0, maxBytes).toString()
}

export async function fetchAndExtract(
  rawUrl: string,
  signal?: AbortSignal,
): Promise<ExtractedContent> {
  const url = await assertPublicUrl(rawUrl)

  const signals = [AbortSignal.timeout(FETCH_TIMEOUT_MS)]
  if (signal) signals.push(signal)
  const response = await fetchGuarded(url, AbortSignal.any(signals))

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

  const html = await readCappedBody(response, MAX_CONTENT_BYTES)

  const finalUrl = response.url || rawUrl
  const { title, content } = contentType.includes("text/plain")
    ? { title: finalUrl, content: html.trim() }
    : htmlToMarkdown(html, finalUrl)

  return { url: finalUrl, title, content: content.slice(0, MAX_STORED_CHARS) }
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
      while (next < items.length) {
        const index = next++
        results[index] = await fn(items[index]!, index)
      }
    },
  )
  await Promise.all(workers)
  return results
}
