// Small render/format helpers shared by the web-search and read-web-page
// extensions. Pure functions with no dependencies so both workspace packages
// can import them across the package boundary.

export function truncate(text: string, max: number): string {
  if (text.length <= max) return text
  return text.slice(0, max - 3) + "..."
}

// Cap long text for the expanded tool-result preview.
export function previewText(text: string): string {
  if (text.length <= 4000) return text
  return text.slice(0, 4000) + "\n..."
}

export function progressBar(progress: number): string {
  const filled = Math.floor(progress * 10)
  return "█".repeat(filled) + "░".repeat(10 - filled)
}

export function errorResult(message: string) {
  return {
    content: [{ type: "text" as const, text: `Error: ${message}` }],
    details: { error: message },
  }
}

// Tools accept a single value or an array; normalize to a raw list.
export function toRawList(single: unknown, multi: unknown): unknown[] {
  if (Array.isArray(multi)) return multi
  if (single !== undefined) return [single]
  return []
}
