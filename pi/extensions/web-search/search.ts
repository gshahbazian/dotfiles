import type { OpenAIAuth } from "./auth"
import { extractAccountId, isCodexJwt } from "./auth"

const OPENAI_RESPONSES_URL = "https://api.openai.com/v1/responses"
const CODEX_RESPONSES_URL = "https://chatgpt.com/backend-api/codex/responses"
const SEARCH_TIMEOUT_MS = 60_000
const MAX_RESULTS = 20
const MAX_FILTER_DOMAINS = 100

export interface SearchResult {
  title: string
  url: string
}

export interface SearchOptions {
  numResults?: number
  recencyFilter?: "day" | "week" | "month" | "year"
  domainFilter?: string[]
  signal?: AbortSignal
}

export interface QueryResultData {
  query: string
  answer: string
  results: SearchResult[]
  error: string | null
}

interface DomainFilters {
  allowed: string[]
  blocked: string[]
}

// The response payloads are untyped JSON; narrow object nodes through this.
function asRec(value: unknown): Record<string, any> | null {
  if (value && typeof value === "object") return value as Record<string, any>
  return null
}

function normalizeDomain(value: string): string | null {
  const input = value.trim().toLowerCase().replace(/^-\s*/, "")
  if (!input) return null

  let host: string
  try {
    host = new URL(input.includes("://") ? input : `https://${input}`).hostname
  } catch {
    return null
  }

  host = host.replace(/^\.+|\.+$/g, "")
  if (!/^[a-z0-9][a-z0-9.-]*\.[a-z]{2,}$/i.test(host)) return null
  return host
}

function parseDomainFilters(
  domainFilter: string[] | undefined,
): DomainFilters | null {
  if (!domainFilter?.length) return null

  const allowed: string[] = []
  const blocked: string[] = []
  for (const raw of domainFilter) {
    const domain = normalizeDomain(raw)
    if (!domain) continue
    const target = raw.trim().startsWith("-") ? blocked : allowed
    if (!target.includes(domain)) target.push(domain)
  }

  if (allowed.length === 0 && blocked.length === 0) return null
  return {
    allowed: allowed.slice(0, MAX_FILTER_DOMAINS),
    blocked: blocked.slice(0, MAX_FILTER_DOMAINS),
  }
}

const RECENCY_LABELS = {
  day: "past 24 hours",
  week: "past week",
  month: "past month",
  year: "past year",
}

function buildInstructions(
  options: SearchOptions,
  filters: DomainFilters | null,
): string {
  const lines = [
    "Search the web and return a concise answer grounded only in the web results.",
    "Include clickable source citations in the response text when possible.",
  ]
  if (options.recencyFilter) {
    lines.push(
      `Prefer sources from the ${RECENCY_LABELS[options.recencyFilter]}.`,
    )
  }
  if (typeof options.numResults === "number" && options.numResults > 0) {
    const count = Math.min(Math.floor(options.numResults), MAX_RESULTS)
    lines.push(`Prefer around ${count} distinct sources.`)
  }
  if (filters?.allowed.length) {
    lines.push(`Only use sources from: ${filters.allowed.join(", ")}.`)
  }
  if (filters?.blocked.length) {
    lines.push(`Do not use sources from: ${filters.blocked.join(", ")}.`)
  }
  return lines.join(" ")
}

function buildWebSearchTool(
  filters: DomainFilters | null,
): Record<string, unknown> {
  if (!filters) return { type: "web_search" }

  const apiFilters: Record<string, unknown> = {}
  if (filters.allowed.length) apiFilters.allowed_domains = filters.allowed
  if (filters.blocked.length) apiFilters.blocked_domains = filters.blocked
  return { type: "web_search", filters: apiFilters }
}

// The request sets stream:true (the Codex backend requires it), so the body is
// usually an SSE stream; tolerate a plain JSON body too.
async function parseOpenAIResponse(
  response: Response,
): Promise<Record<string, unknown>> {
  const text = (await response.text()).trim()

  if (text.startsWith("{") || text.startsWith("[")) {
    let parsed: unknown
    try {
      parsed = JSON.parse(text)
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err)
      throw new Error(`OpenAI API returned invalid JSON: ${message}`)
    }
    if (Array.isArray(parsed)) return { output: parsed }
    return asRec(parsed) ?? { output: [] }
  }

  // SSE stream: collect completed output items.
  const outputItems: unknown[] = []
  let completed: Record<string, unknown> | null = null
  for (const line of text.split("\n")) {
    if (!line.startsWith("data: ")) continue
    const data = line.slice(6).trim()
    if (!data || data === "[DONE]") continue

    let event: Record<string, any> | null
    try {
      event = asRec(JSON.parse(data))
    } catch {
      continue // skip malformed SSE lines
    }
    if (!event) continue

    if (event.type === "response.output_item.done" && event.item) {
      outputItems.push(event.item)
    }
    const isDone =
      event.type === "response.done" || event.type === "response.completed"
    if (isDone && asRec(event.response)) {
      completed = event.response
    }
  }

  if (completed) {
    if (Array.isArray(completed.output) && completed.output.length > 0) {
      return completed
    }
    return { ...completed, output: outputItems }
  }
  if (outputItems.length > 0) return { output: outputItems }
  throw new Error("OpenAI API returned no parseable response output")
}

function cleanSourceUrl(rawUrl: string): string {
  try {
    const url = new URL(rawUrl)
    if (url.searchParams.get("utm_source") === "openai") {
      url.searchParams.delete("utm_source")
    }
    return url.toString()
  } catch {
    return rawUrl.replace(/[?&]utm_source=openai$/, "")
  }
}

function addResult(
  results: SearchResult[],
  seen: Set<string>,
  url: unknown,
  title: unknown,
): void {
  if (typeof url !== "string" || !url.trim()) return

  const cleanUrl = cleanSourceUrl(url)
  if (seen.has(cleanUrl)) return
  seen.add(cleanUrl)

  const hasTitle = typeof title === "string" && title.trim().length > 0
  results.push({ title: hasTitle ? title : cleanUrl, url: cleanUrl })
}

function extractSearchResults(
  output: unknown[],
  numResults: number | undefined,
): SearchResult[] {
  const results: SearchResult[] = []
  const seen = new Set<string>()
  const items = output.map(asRec)

  // Citations attached to the synthesized message.
  for (const item of items) {
    if (item?.type !== "message" || !Array.isArray(item.content)) continue
    for (const part of item.content.map(asRec)) {
      if (!Array.isArray(part?.annotations)) continue
      for (const note of part.annotations.map(asRec)) {
        if (note?.type !== "url_citation") continue
        addResult(results, seen, note.url, note.title)
      }
    }
  }

  // Sources surfaced by the web_search tool call itself.
  for (const item of items) {
    if (item?.type !== "web_search_call") continue
    for (const group of [
      asRec(item.action)?.sources,
      item.sources,
      item.results,
    ]) {
      if (!Array.isArray(group)) continue
      for (const source of group.map(asRec)) {
        if (!source) continue
        addResult(
          results,
          seen,
          source.url ?? source.source_website_url,
          source.title ?? source.caption,
        )
      }
    }
  }

  if (typeof numResults === "number" && numResults > 0) {
    return results.slice(0, Math.min(Math.floor(numResults), MAX_RESULTS))
  }
  return results
}

function extractAnswer(output: unknown[]): string {
  const parts: string[] = []
  for (const item of output.map(asRec)) {
    if (item?.type !== "message" || !Array.isArray(item.content)) continue
    for (const part of item.content.map(asRec)) {
      if (typeof part?.text === "string" && part.text.trim()) {
        parts.push(part.text)
      }
    }
  }
  return parts.join("\n").trim()
}

export async function searchWithOpenAI(
  query: string,
  options: SearchOptions,
  auth: OpenAIAuth,
): Promise<{ answer: string; results: SearchResult[] }> {
  const headers: Record<string, string> = {
    ...auth.headers,
    Authorization: `Bearer ${auth.apiKey}`,
    "Content-Type": "application/json",
    "OpenAI-Beta": "responses=experimental",
  }

  const useCodex = auth.provider === "openai-codex" || isCodexJwt(auth.apiKey)
  if (useCodex) {
    const accountId = extractAccountId(auth.apiKey)
    if (accountId) headers["chatgpt-account-id"] = accountId
    headers.originator = "pi"
  }

  const filters = parseDomainFilters(options.domainFilter)
  const body = {
    model: auth.model,
    instructions: buildInstructions(options, filters),
    input: [{ role: "user", content: [{ type: "input_text", text: query }] }],
    tools: [buildWebSearchTool(filters)],
    include: ["web_search_call.action.sources"],
    store: false,
    stream: true,
    tool_choice: "required" as const,
    parallel_tool_calls: true,
  }

  const signals = [AbortSignal.timeout(SEARCH_TIMEOUT_MS)]
  if (options.signal) signals.push(options.signal)

  const response = await fetch(
    useCodex ? CODEX_RESPONSES_URL : OPENAI_RESPONSES_URL,
    {
      method: "POST",
      headers,
      body: JSON.stringify(body),
      signal: AbortSignal.any(signals),
    },
  )
  if (!response.ok) {
    const errorText = await response.text()
    throw new Error(
      `OpenAI API error ${response.status}: ${errorText.slice(0, 300)}`,
    )
  }

  const parsed = await parseOpenAIResponse(response)
  const output = Array.isArray(parsed.output) ? parsed.output : []
  const answer = extractAnswer(output)
  const results = extractSearchResults(output, options.numResults)
  if (!answer && results.length === 0) {
    throw new Error("OpenAI web_search returned no answer or sources")
  }
  return { answer, results }
}

export function formatSearchSummary(
  results: SearchResult[],
  answer: string,
): string {
  const sources = results
    .map((r, i) => `${i + 1}. ${r.title}\n   ${r.url}`)
    .join("\n")

  if (!answer) return sources
  return `${answer}\n\n---\n\n**Sources:**\n${sources}`
}

export function normalizeQueryList(raw: unknown[]): string[] {
  const seen = new Set<string>()
  const out: string[] = []
  for (const item of raw) {
    if (typeof item !== "string") continue
    const query = item.trim()
    if (!query || seen.has(query)) continue
    seen.add(query)
    out.push(query)
  }
  return out
}
