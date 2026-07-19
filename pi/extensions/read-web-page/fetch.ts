import { parseHTML } from "linkedom"
import { Defuddle } from "defuddle/node"

// Web pages -> markdown.

export interface ExtractedContent {
  url: string
  title: string
  content: string
  error?: string
}

const FETCH_TIMEOUT_MS = 30_000
const MAX_STORED_CHARS = 500_000
const MIN_USEFUL_CONTENT = 200

const FETCH_HEADERS = {
  "User-Agent":
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Safari/537.36",
  Accept: "text/html,application/xhtml+xml,text/plain;q=0.9,*/*;q=0.8",
}

async function htmlToMarkdown(
  html: string,
  fallbackUrl: string,
): Promise<{ title: string; content: string }> {
  // linkedom + defuddle aren't typed against this DOM-less tsconfig, so we
  // cross the boundary with `any` casts.
  const { document } = parseHTML(html)
  // The page's raw text is our fallback whenever defuddle can't produce useful
  // markdown (extraction stripped too much, or threw).
  const rawText = ((document as any).body?.textContent ?? "").trim()

  try {
    const result = await Defuddle(document as any, fallbackUrl, {
      markdown: true,
    })
    const title = result.title?.trim() || fallbackUrl
    const content = (result.content ?? "").trim()

    // Defuddle can over-strip and leave us with almost nothing; prefer the raw
    // page text in that case so we still return something useful.
    if (
      content.length < MIN_USEFUL_CONTENT &&
      rawText.length > content.length
    ) {
      return { title, content: rawText }
    }
    return { title, content }
  } catch {
    return { title: fallbackUrl, content: rawText || html.trim() }
  }
}

export async function fetchAndExtract(
  rawUrl: string,
  signal?: AbortSignal,
): Promise<ExtractedContent> {
  const signals = [AbortSignal.timeout(FETCH_TIMEOUT_MS)]
  if (signal) signals.push(signal)
  const response = await fetch(rawUrl, {
    headers: FETCH_HEADERS,
    signal: AbortSignal.any(signals),
  })

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

  const html = await response.text()

  const finalUrl = response.url || rawUrl
  const { title, content } = contentType.includes("text/plain")
    ? { title: finalUrl, content: html.trim() }
    : await htmlToMarkdown(html, finalUrl)

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
