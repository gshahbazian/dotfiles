import {
  mkdirSync,
  readdirSync,
  rmSync,
  statSync,
  writeFileSync,
} from "node:fs"
import { tmpdir } from "node:os"
import { join } from "node:path"
import type { ExtractedContent } from "./fetch"

// Fetched pages are written here so the agent can grep/read them with its own
// file tools instead of us paging content back through the model context.
const CACHE_DIR = join(tmpdir(), "pi-web-search")
const MAX_AGE_MS = 24 * 60 * 60 * 1000
const MAX_OUTLINE_HEADINGS = 60

export interface SavedPage {
  path: string
  chars: number
  lines: number
  outline: string
}

function generateId(): string {
  return Date.now().toString(36) + Math.random().toString(36).slice(2, 8)
}

function slugify(text: string): string {
  const slug = text
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 40)
  return slug || "page"
}

// Markdown H1-H3 outline, each heading tagged with its line number in the
// saved file so the agent can jump straight to a section with an offset read.
// Skips fenced code blocks so `# comment` lines aren't mistaken for headings.
function buildOutline(markdown: string, lineOffset: number): string {
  const headings: string[] = []
  let inFence = false

  const lines = markdown.split("\n")
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i]!
    if (line.startsWith("```")) {
      inFence = !inFence
      continue
    }
    if (inFence) continue

    const match = /^(#{1,3})\s+(.+?)\s*#*$/.exec(line)
    if (!match) continue
    const text = match[2]!.trim()
    if (!text) continue

    const indent = "  ".repeat(match[1]!.length - 1)
    headings.push(`${indent}${match[1]} ${text}  [L${i + 1 + lineOffset}]`)
    if (headings.length >= MAX_OUTLINE_HEADINGS) break
  }
  return headings.join("\n")
}

export function savePage(content: ExtractedContent): SavedPage {
  mkdirSync(CACHE_DIR, { recursive: true })

  const path = join(CACHE_DIR, `${generateId()}-${slugify(content.title)}.md`)
  const header = `# ${content.title}\n${content.url}\n\n`
  const body = `${header}${content.content}\n`
  writeFileSync(path, body, { mode: 0o600 })

  return {
    path,
    chars: body.length,
    lines: body.split("\n").length,
    outline: buildOutline(content.content, header.split("\n").length - 1),
  }
}

// Best-effort sweep of stale cache files. Runs once on extension load.
export function cleanupCache(): void {
  let entries: string[]
  try {
    entries = readdirSync(CACHE_DIR)
  } catch {
    return // dir doesn't exist yet
  }

  const now = Date.now()
  for (const name of entries) {
    const path = join(CACHE_DIR, name)
    try {
      if (now - statSync(path).mtimeMs > MAX_AGE_MS) rmSync(path)
    } catch {
      // Ignore files that vanish mid-sweep.
    }
  }
}
