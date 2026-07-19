import type { ExtensionAPI } from "@earendil-works/pi-coding-agent"
import { Box, Text } from "@earendil-works/pi-tui"
import { Type } from "typebox"
import {
  errorResult,
  previewText,
  progressBar,
  toRawList,
  truncate,
} from "../shared/render"
import {
  fetchAndExtract,
  mapWithConcurrency,
  type ExtractedContent,
} from "./fetch"
import { cleanupCache, savePage } from "./files"

// Fetch web page(s) -> readable markdown saved to a file, with a line-numbered
// heading outline the agent can grep/read. Split out of the web-search
// extension so reading pages and searching the web are independent tools.

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

export default function readWebPage(pi: ExtensionAPI) {
  cleanupCache()

  pi.registerTool({
    name: "read_page",
    label: "Read Page",
    description:
      "Read the contents of one or more web pages. Fetches each URL, extracts the readable content as Markdown, and saves it to a file under the OS temp dir — returning the file path plus a heading outline (each heading tagged with its line number, e.g. [L42]). Use your normal file tools to read a section by line offset, or grep the file for the full content. Accepts a single 'url' or multiple 'urls' (fetched concurrently). Do NOT use for localhost or local URLs — use `curl` via Bash instead.",
    promptSnippet:
      "Use to read the contents of web page URLs. Each page is saved to a file with a line-numbered heading outline; read by line offset or grep the returned path for full content. For localhost or local URLs, use `curl` via Bash instead.",
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
        return errorResult("No URL provided. Use 'url' or 'urls'.")
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
              details: { progress: done / urls.length },
            })
          }
        },
      )

      const multi = extracted.length > 1
      const output = extracted
        .map((page, i) => formatFetchBlock(page, multi ? i : undefined))
        .join("\n\n")

      return {
        content: [{ type: "text", text: output.trim() }],
        details: {
          urlCount: extracted.length,
          successfulUrls: extracted.filter((c) => !c.error).length,
        },
      }
    },

    renderCall(args, theme) {
      const input = args as { url?: unknown; urls?: unknown }
      const urls = stringList(input.url, input.urls)
      const title = theme.fg("toolTitle", theme.bold("read "))

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
        progress?: number
      }

      if (isPartial) {
        const bar = progressBar(details?.progress ?? 0)
        return new Text(theme.fg("accent", `[${bar}] fetching`), 0, 0)
      }
      if (details?.error) {
        return new Text(theme.fg("error", `Error: ${details.error}`), 0, 0)
      }

      const statusLine = theme.fg(
        "success",
        `${details?.successfulUrls ?? 0}/${details?.urlCount ?? 0} pages fetched`,
      )
      if (!expanded) {
        const box = new Box(1, 0, (t) => theme.bg("toolSuccessBg", t))
        box.addChild(new Text(statusLine, 0, 0))
        return box
      }

      const textContent =
        result.content.find((c) => c.type === "text")?.text ?? ""
      return new Text(
        statusLine + "\n\n" + theme.fg("dim", previewText(textContent)),
        0,
        0,
      )
    },
  })
}
