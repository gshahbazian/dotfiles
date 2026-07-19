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
  errorResult,
  previewText,
  progressBar,
  toRawList,
  truncate,
} from "../shared/render"

// Simplified openai-only rewrite of `pi-web-access`.

function collectQueries(single: unknown, multi: unknown): string[] {
  return normalizeQueryList(toRawList(single, multi))
}

export default function webSearch(pi: ExtensionAPI) {
  // ----- web_search -------------------------------------------------------
  pi.registerTool({
    name: "web_search",
    label: "Web Search",
    description:
      "Search the web and get back an AI-synthesized answer with source citations. For research, prefer {queries:[...]} with 2-4 varied angles over a single query — each query gets its own synthesized answer, so varying phrasing and scope gives much broader coverage. To read a specific URL you already have, use read_page instead.",
    promptSnippet:
      "Use for open-ended web research. Prefer {queries:[...]} with 2-4 varied angles over a single query for broader coverage. To read a specific known URL, use read_page instead.",
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
        return errorResult("No query provided. Use 'query' or 'queries'.")
      }

      const auth = await resolveOpenAIAuth(ctx)
      if (!auth) return errorResult(AUTH_HELP)

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
          details: { progress: i / queries.length, currentQuery: query },
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

      return {
        content: [{ type: "text", text: output.trim() }],
        details: {
          queryCount: queries.length,
          successfulQueries: queryResults.filter((r) => !r.error).length,
          totalResults: queryResults.reduce(
            (sum, r) => sum + r.results.length,
            0,
          ),
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
        progress?: number
        currentQuery?: string
      }

      if (isPartial) {
        const bar = progressBar(details?.progress ?? 0)
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

        // First line of the synthesized answer as a teaser.
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
}
