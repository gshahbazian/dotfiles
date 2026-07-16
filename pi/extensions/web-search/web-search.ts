import { StringEnum } from "@earendil-works/pi-ai/compat"
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent"
import { Box, Text } from "@earendil-works/pi-tui"
import { Type } from "typebox"
import { AUTH_HELP, resolveOpenAIAuth } from "./auth"
import {
  formatSearchSummary,
  normalizeQueryList,
  searchWithOpenAI,
  type QueryResultData,
  type SearchOptions,
} from "./search"
import {
  fetchAndExtract,
  mapWithConcurrency,
  type ExtractedContent,
} from "./fetch"
import { cleanupCache, savePage } from "./files"

// simplified openai-only rewrite of `pi-web-access`

// Cap a display string, keeping the total length at `max` (ellipsis included).
function truncate(text: string, max: number): string {
  if (text.length <= max) return text
  return text.slice(0, max - 3) + "..."
}

// Cap long text for the expanded tool-result preview shown in the TUI.
function previewText(text: string): string {
  if (text.length <= 4000) return text
  return text.slice(0, 4000) + "\n..."
}

// Both tools accept a single value or an array; normalize to a raw list.
function toRawList(single: unknown, multi: unknown): unknown[] {
  if (Array.isArray(multi)) return multi
  if (single !== undefined) return [single]
  return []
}

function collectQueries(single: unknown, multi: unknown): string[] {
  return normalizeQueryList(toRawList(single, multi))
}

function stringList(single: unknown, multi: unknown): string[] {
  return toRawList(single, multi).filter(
    (u): u is string => typeof u === "string",
  )
}

// A fetched page: save the full markdown to a file, then hand the agent the
// path plus a heading outline so it can grep/read exactly what it needs.
function formatFetchBlock(page: ExtractedContent, index?: number): string {
  const label = index === undefined ? "" : `[${index}] `
  const header = `## ${label}${page.title}\n${page.url}`
  if (page.error) return `${header}\n\nError: ${page.error}`

  const saved = savePage(page)
  let block = `${header}\nSaved to: ${saved.path}  (${saved.chars} chars, ${saved.lines} lines)\n`
  if (saved.outline) {
    block += `\nOutline:\n${saved.outline}`
  } else {
    const lead = page.content.slice(0, 400).trim()
    const more = page.content.length > 400 ? "\n..." : ""
    block += `\nNo headings found. Lead:\n${lead}${more}`
  }
  return block
}

export default function webSearch(pi: ExtensionAPI) {
  cleanupCache()

  // ----- web_search -------------------------------------------------------
  pi.registerTool({
    name: "web_search",
    label: "Web Search",
    description:
      "Search the web via OpenAI's web_search (Codex subscription or OpenAI API key). Returns an AI-synthesized answer with source citations. For research, prefer {queries:[...]} with 2-4 varied angles over a single query — each query gets its own synthesized answer, so varying phrasing and scope gives much broader coverage.",
    promptSnippet:
      "Use for web research questions. Prefer {queries:[...]} with 2-4 varied angles over a single query for broader coverage.",
    parameters: Type.Object({
      query: Type.Optional(
        Type.String({
          description:
            "Single search query. For research, prefer 'queries' with varied angles.",
        }),
      ),
      queries: Type.Optional(
        Type.Array(Type.String(), {
          description:
            "Multiple queries searched in sequence, each returning its own synthesized answer. Vary phrasing, scope, and angle across 2-4 queries for maximum coverage.",
        }),
      ),
      numResults: Type.Optional(
        Type.Number({
          description:
            "Cap on results per query (max 20). Omit to return all sources found.",
        }),
      ),
      recencyFilter: Type.Optional(
        StringEnum(["day", "week", "month", "year"], {
          description: "Filter by recency",
        }),
      ),
      domainFilter: Type.Optional(
        Type.Array(Type.String(), {
          description: "Limit to domains (prefix with - to exclude)",
        }),
      ),
    }),

    async execute(_callId, params, signal, onUpdate, ctx) {
      const queries = collectQueries(params.query, params.queries)

      if (queries.length === 0) {
        return {
          content: [
            {
              type: "text",
              text: "Error: No query provided. Use 'query' or 'queries'.",
            },
          ],
          details: { error: "No query provided" },
        }
      }

      const auth = await resolveOpenAIAuth(ctx)
      if (!auth) {
        return {
          content: [{ type: "text", text: `Error: ${AUTH_HELP}` }],
          details: { error: "OpenAI web search unavailable" },
        }
      }

      const options: SearchOptions = {
        numResults: params.numResults,
        recencyFilter: params.recencyFilter as SearchOptions["recencyFilter"],
        domainFilter: params.domainFilter,
        signal,
      }

      const queryResults: QueryResultData[] = []
      for (let i = 0; i < queries.length; i++) {
        const query = queries[i]!
        onUpdate?.({
          content: [
            {
              type: "text",
              text: `Searching ${i + 1}/${queries.length}: "${query}"...`,
            },
          ],
          details: {
            phase: "search",
            progress: i / queries.length,
            currentQuery: query,
          },
        })
        try {
          const { answer, results } = await searchWithOpenAI(
            query,
            options,
            auth,
          )
          queryResults.push({ query, answer, results, error: null })
        } catch (err) {
          const message = err instanceof Error ? err.message : String(err)
          queryResults.push({ query, answer: "", results: [], error: message })
        }
      }

      // Build the model-facing text.
      let output = ""
      for (const { query, answer, results, error } of queryResults) {
        if (queries.length > 1) output += `## Query: "${query}"\n\n`
        if (error) {
          output += `Error: ${error}\n\n`
          continue
        }
        if (results.length === 0) {
          output += "No results found.\n\n"
          continue
        }
        output += `${formatSearchSummary(results, answer)}\n\n`
      }

      const successful = queryResults.filter((r) => !r.error).length
      const totalResults = queryResults.reduce(
        (sum, r) => sum + r.results.length,
        0,
      )

      return {
        content: [{ type: "text", text: output.trim() }],
        details: {
          queries,
          queryCount: queries.length,
          successfulQueries: successful,
          totalResults,
        },
      }
    },

    renderCall(args, theme) {
      const input = args as { query?: unknown; queries?: unknown }
      const queries = collectQueries(input.query, input.queries)
      const title = theme.fg("toolTitle", theme.bold("search "))
      if (queries.length === 0) {
        return new Text(title + theme.fg("error", "(no query)"), 0, 0)
      }
      if (queries.length === 1) {
        const display = truncate(queries[0]!, 60)
        return new Text(title + theme.fg("accent", `"${display}"`), 0, 0)
      }
      const lines = [title + theme.fg("accent", `${queries.length} queries`)]
      for (const q of queries.slice(0, 5)) {
        lines.push(theme.fg("muted", `  "${truncate(q, 50)}"`))
      }
      if (queries.length > 5) {
        lines.push(theme.fg("muted", `  ... and ${queries.length - 5} more`))
      }
      return new Text(lines.join("\n"), 0, 0)
    },

    renderResult(result, { expanded, isPartial }, theme) {
      const details = result.details as {
        error?: string
        queryCount?: number
        successfulQueries?: number
        totalResults?: number
        phase?: string
        progress?: number
        currentQuery?: string
      }

      if (isPartial) {
        const progress = details?.progress ?? 0
        const filled = Math.floor(progress * 10)
        const bar = "█".repeat(filled) + "░".repeat(10 - filled)
        const display = truncate(details?.currentQuery ?? "", 40)
        return new Text(theme.fg("accent", `[${bar}] ${display}`), 0, 0)
      }

      if (details?.error) {
        return new Text(theme.fg("error", `Error: ${details.error}`), 0, 0)
      }

      const queryInfo =
        details?.queryCount === 1
          ? ""
          : `${details?.successfulQueries}/${details?.queryCount} queries, `
      const statusLine = theme.fg(
        "success",
        `${queryInfo}${details?.totalResults ?? 0} sources`,
      )
      const textContent =
        result.content.find((c) => c.type === "text")?.text ?? ""

      if (!expanded) {
        const box = new Box(1, 0, (t) => theme.bg("toolSuccessBg", t))
        box.addChild(new Text(statusLine, 0, 0))
        const firstLine = textContent.split("\n").find((l) => {
          const t = l.trim()
          if (!t) return false
          return (
            !t.startsWith("#") && !t.startsWith("---") && !t.startsWith("[")
          )
        })
        if (firstLine) {
          const clean = firstLine.trim().replace(/\*\*/g, "")
          box.addChild(new Text(theme.fg("dim", truncate(clean, 120)), 0, 0))
        }
        return box
      }

      return new Text(
        statusLine + "\n\n" + theme.fg("dim", previewText(textContent)),
        0,
        0,
      )
    },
  })

  // ----- fetch_content ----------------------------------------------------
  pi.registerTool({
    name: "fetch_content",
    label: "Fetch Content",
    description:
      "Fetch web page(s), extract the readable content as markdown, and save each to a file under the OS temp dir. Returns the file path and a heading outline (each heading tagged with its line number, e.g. [L42]) for each page — use your normal file tools to read a section by line offset or grep the file for the full content. Accepts a single 'url' or multiple 'urls' (fetched concurrently). Private/loopback addresses are refused.",
    promptSnippet:
      "Use to fetch web page URLs. Each page is saved to a file with a line-numbered heading outline; read by line offset or grep the returned path for full content.",
    parameters: Type.Object({
      url: Type.Optional(Type.String({ description: "Single URL to fetch" })),
      urls: Type.Optional(
        Type.Array(Type.String(), {
          description: "Multiple URLs (concurrent)",
        }),
      ),
    }),

    async execute(_callId, params, signal, onUpdate) {
      const urls = stringList(params.url, params.urls)
        .map((u) => u.trim())
        .filter((u) => u.length > 0)

      if (urls.length === 0) {
        return {
          content: [
            {
              type: "text",
              text: "Error: No URL provided. Use 'url' or 'urls'.",
            },
          ],
          details: { error: "No URL provided" },
        }
      }

      let done = 0
      const extracted = await mapWithConcurrency(
        urls,
        3,
        async (url): Promise<ExtractedContent> => {
          try {
            return await fetchAndExtract(url, signal)
          } catch (err) {
            const message = err instanceof Error ? err.message : String(err)
            return { url, title: url, content: "", error: message }
          } finally {
            done++
            onUpdate?.({
              content: [
                { type: "text", text: `Fetched ${done}/${urls.length}...` },
              ],
              details: { phase: "fetch", progress: done / urls.length },
            })
          }
        },
      )

      const multi = extracted.length > 1
      const output = extracted
        .map((page, i) => formatFetchBlock(page, multi ? i : undefined))
        .join("\n\n")

      const succeeded = extracted.filter((c) => !c.error).length
      return {
        content: [{ type: "text", text: output.trim() }],
        details: {
          urlCount: extracted.length,
          successfulUrls: succeeded,
        },
      }
    },

    renderCall(args, theme) {
      const input = args as { url?: unknown; urls?: unknown }
      const urls = stringList(input.url, input.urls)
      const title = theme.fg("toolTitle", theme.bold("fetch "))
      if (urls.length === 0) {
        return new Text(title + theme.fg("error", "(no url)"), 0, 0)
      }
      if (urls.length === 1) {
        return new Text(
          title + theme.fg("accent", truncate(urls[0]!, 60)),
          0,
          0,
        )
      }
      return new Text(title + theme.fg("accent", `${urls.length} URLs`), 0, 0)
    },

    renderResult(result, { expanded, isPartial }, theme) {
      const details = result.details as {
        error?: string
        urlCount?: number
        successfulUrls?: number
        phase?: string
        progress?: number
      }

      if (isPartial) {
        const progress = details?.progress ?? 0
        const filled = Math.floor(progress * 10)
        const bar = "█".repeat(filled) + "░".repeat(10 - filled)
        return new Text(theme.fg("accent", `[${bar}] fetching`), 0, 0)
      }

      if (details?.error) {
        return new Text(theme.fg("error", `Error: ${details.error}`), 0, 0)
      }

      const statusLine = theme.fg(
        "success",
        `${details?.successfulUrls ?? 0}/${details?.urlCount ?? 0} pages fetched`,
      )
      const textContent =
        result.content.find((c) => c.type === "text")?.text ?? ""

      if (!expanded) {
        const box = new Box(1, 0, (t) => theme.bg("toolSuccessBg", t))
        box.addChild(new Text(statusLine, 0, 0))
        return box
      }
      return new Text(
        statusLine + "\n\n" + theme.fg("dim", previewText(textContent)),
        0,
        0,
      )
    },
  })
}
