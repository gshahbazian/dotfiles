import type { OpenAIAuth } from "./auth"
import { extractAccountId, isCodexJwt } from "./auth"

const OPENAI_RESPONSES_URL = "https://api.openai.com/v1/responses"
const CODEX_RESPONSES_URL = "https://chatgpt.com/backend-api/codex/responses"
const SEARCH_TIMEOUT_MS = 60_000

export interface SearchResult {
  title: string
  url: string
  snippet: string
}

interface SearchResponse {
  answer: string
  results: SearchResult[]
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

interface NormalizedDomains {
  allowedDomains?: string[]
  blockedDomains?: string[]
}

function normalizeDomain(value: string): string | null {
  let input = value.trim().toLowerCase()
  if (!input) return null
  if (input.startsWith("-")) input = input.slice(1).trim()
  if (!input) return null
  try {
    const parsed = input.includes("://")
      ? new URL(input)
      : new URL(`https://${input}`)
    input = parsed.hostname
  } catch {
    input = input.split("/")[0]?.split(":")[0] ?? ""
  }
  input = input.replace(/^\.+|\.+$/g, "")
  return /^[a-z0-9][a-z0-9.-]*\.[a-z]{2,}$/i.test(input) ? input : null
}

function normalizeDomainFilters(
  domainFilter: string[] | undefined,
): NormalizedDomains | null {
  if (!domainFilter?.length) return null
  const allowedDomains: string[] = []
  const blockedDomains: string[] = []
  for (const raw of domainFilter) {
    const domain = normalizeDomain(raw)
    if (!domain) continue
    const target = raw.trim().startsWith("-") ? blockedDomains : allowedDomains
    if (!target.includes(domain)) target.push(domain)
  }
  if (allowedDomains.length === 0 && blockedDomains.length === 0) return null
  const result: NormalizedDomains = {}
  if (allowedDomains.length) {
    result.allowedDomains = allowedDomains.slice(0, 100)
  }
  if (blockedDomains.length) {
    result.blockedDomains = blockedDomains.slice(0, 100)
  }
  return result
}

function buildInstructions(options: SearchOptions): string {
  const lines = [
    "Search the web and return a concise answer grounded only in the web results.",
    "Include clickable source citations in the response text when possible.",
  ]
  if (options.recencyFilter) {
    const labels: Record<string, string> = {
      day: "past 24 hours",
      week: "past week",
      month: "past month",
      year: "past year",
    }
    lines.push(`Prefer sources from the ${labels[options.recencyFilter]}.`)
  }
  if (typeof options.numResults === "number" && options.numResults > 0) {
    lines.push(
      `Prefer around ${Math.min(Math.floor(options.numResults), 20)} distinct sources.`,
    )
  }
  const filters = normalizeDomainFilters(options.domainFilter)
  if (filters?.allowedDomains?.length) {
    lines.push(`Only use sources from: ${filters.allowedDomains.join(", ")}.`)
  }
  if (filters?.blockedDomains?.length) {
    lines.push(`Do not use sources from: ${filters.blockedDomains.join(", ")}.`)
  }
  return lines.join(" ")
}

function buildWebSearchTool(options: SearchOptions): Record<string, unknown> {
  const tool: Record<string, unknown> = { type: "web_search" }
  const filters = normalizeDomainFilters(options.domainFilter)
  if (!filters) return tool

  const apiFilters: Record<string, unknown> = {}
  if (filters.allowedDomains) {
    apiFilters.allowed_domains = filters.allowedDomains
  }
  if (filters.blockedDomains) {
    apiFilters.blocked_domains = filters.blockedDomains
  }
  tool.filters = apiFilters
  return tool
}

async function parseOpenAIResponse(
  response: Response,
): Promise<Record<string, unknown>> {
  const text = await response.text()
  const trimmed = text.trim()
  if (trimmed.startsWith("{") || trimmed.startsWith("[")) {
    try {
      const parsed = JSON.parse(trimmed)
      if (Array.isArray(parsed)) return { output: parsed }
      if (parsed && typeof parsed === "object") {
        return parsed as Record<string, unknown>
      }
      return { output: [] }
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err)
      throw new Error(`OpenAI API returned invalid JSON: ${message}`)
    }
  }

  // Server-sent event stream: collect completed output items.
  const outputItems: unknown[] = []
  let completed: Record<string, unknown> | null = null
  for (const line of text.split("\n")) {
    if (!line.startsWith("data: ")) continue
    const data = line.slice(6).trim()
    if (!data || data === "[DONE]") continue
    try {
      const parsed = JSON.parse(data) as Record<string, unknown>
      if (parsed.type === "response.output_item.done" && parsed.item) {
        outputItems.push(parsed.item)
      }
      if (
        (parsed.type === "response.done" ||
          parsed.type === "response.completed") &&
        parsed.response &&
        typeof parsed.response === "object"
      ) {
        completed = parsed.response as Record<string, unknown>
      }
    } catch {
      // Skip malformed SSE lines.
    }
  }

  if (completed) {
    const output = Array.isArray(completed.output) ? completed.output : []
    if (output.length > 0) return completed
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

function snippetAround(text: string, start: unknown, end: unknown): string {
  if (typeof start !== "number" || typeof end !== "number" || !text) return ""
  const before = Math.max(0, start - 100)
  const after = Math.min(text.length, end + 100)
  const snippet = text
    .slice(before, after)
    .replace(/\[([^\]]*)\]\([^)]*\)/g, "$1")
    .trim()
  return snippet.length > 300 ? `${snippet.slice(0, 297)}...` : snippet
}

function addResult(
  results: SearchResult[],
  seen: Set<string>,
  url: unknown,
  title: unknown,
  snippet = "",
): void {
  if (typeof url !== "string" || url.trim().length === 0) return
  const cleanUrl = cleanSourceUrl(url)
  if (seen.has(cleanUrl)) return
  seen.add(cleanUrl)
  results.push({
    title:
      typeof title === "string" && title.trim().length > 0 ? title : cleanUrl,
    url: cleanUrl,
    snippet,
  })
}

function extractSearchResults(
  output: unknown[],
  numResults: number | undefined,
): SearchResult[] {
  const results: SearchResult[] = []
  const seen = new Set<string>()

  // Citations attached to the synthesized message.
  for (const item of output) {
    if (
      !item ||
      typeof item !== "object" ||
      (item as { type?: unknown }).type !== "message"
    ) {
      continue
    }
    const content = (item as { content?: unknown }).content
    if (!Array.isArray(content)) continue
    for (const part of content) {
      if (!part || typeof part !== "object") continue
      const rawText = (part as { text?: unknown }).text
      const text = typeof rawText === "string" ? rawText : ""
      const annotations = (part as { annotations?: unknown }).annotations
      if (!Array.isArray(annotations)) continue
      for (const annotation of annotations) {
        if (
          !annotation ||
          typeof annotation !== "object" ||
          (annotation as { type?: unknown }).type !== "url_citation"
        ) {
          continue
        }
        addResult(
          results,
          seen,
          (annotation as { url?: unknown }).url,
          (annotation as { title?: unknown }).title,
          snippetAround(
            text,
            (annotation as { start_index?: unknown }).start_index,
            (annotation as { end_index?: unknown }).end_index,
          ),
        )
      }
    }
  }

  // Sources surfaced by the web_search tool call itself.
  for (const item of output) {
    if (
      !item ||
      typeof item !== "object" ||
      (item as { type?: unknown }).type !== "web_search_call"
    ) {
      continue
    }
    const value = item as {
      action?: unknown
      sources?: unknown
      results?: unknown
    }
    const actionSources =
      value.action && typeof value.action === "object"
        ? (value.action as { sources?: unknown }).sources
        : undefined
    for (const group of [actionSources, value.sources, value.results]) {
      if (!Array.isArray(group)) continue
      for (const source of group) {
        if (!source || typeof source !== "object") continue
        const record = source as Record<string, unknown>
        addResult(
          results,
          seen,
          record.url ?? record.source_website_url,
          record.title ?? record.caption,
        )
      }
    }
  }

  if (typeof numResults === "number" && numResults > 0) {
    return results.slice(0, Math.min(Math.floor(numResults), 20))
  }
  return results
}

function extractAnswer(output: unknown[]): string {
  const parts: string[] = []
  for (const item of output) {
    if (
      !item ||
      typeof item !== "object" ||
      (item as { type?: unknown }).type !== "message"
    ) {
      continue
    }
    const content = (item as { content?: unknown }).content
    if (!Array.isArray(content)) continue
    for (const part of content) {
      if (!part || typeof part !== "object") continue
      const text = (part as { text?: unknown }).text
      if (typeof text === "string" && text.trim().length > 0) parts.push(text)
    }
  }
  return parts.join("\n").trim()
}

export async function searchWithOpenAI(
  query: string,
  options: SearchOptions,
  auth: OpenAIAuth,
): Promise<SearchResponse> {
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

  const body = {
    model: auth.model,
    instructions: buildInstructions(options),
    input: [{ role: "user", content: [{ type: "input_text", text: query }] }],
    tools: [buildWebSearchTool(options)],
    include: ["web_search_call.action.sources"],
    store: false,
    stream: true,
    tool_choice: "required" as const,
    parallel_tool_calls: true,
  }

  const timeout = AbortSignal.timeout(SEARCH_TIMEOUT_MS)
  const signal = options.signal
    ? AbortSignal.any([timeout, options.signal])
    : timeout

  const response = await fetch(
    useCodex ? CODEX_RESPONSES_URL : OPENAI_RESPONSES_URL,
    {
      method: "POST",
      headers,
      body: JSON.stringify(body),
      signal,
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
    .map((r, i) => {
      let line = `${i + 1}. ${r.title}\n   ${r.url}`
      if (r.snippet) line += `\n   ${r.snippet}`
      return line
    })
    .join("\n\n")
  if (!answer) return sources
  return `${answer}\n\n---\n\n**Sources:**\n${sources}`
}

export function normalizeQueryList(raw: unknown[]): string[] {
  const seen = new Set<string>()
  const out: string[] = []
  for (const item of raw) {
    if (typeof item !== "string") continue
    const q = item.trim()
    if (!q || seen.has(q)) continue
    seen.add(q)
    out.push(q)
  }
  return out
}
