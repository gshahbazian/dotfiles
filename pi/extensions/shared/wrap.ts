import { visibleWidth, wrapTextWithAnsi } from "@earendil-works/pi-tui"

// Push `text` onto `lines`, wrapped to `width`, with `prefix` on the first line
// and an equal-width indent on the continuations.
export function addWrappedLine(
  lines: string[],
  prefix: string,
  text: string,
  width: number,
): void {
  const prefixWidth = visibleWidth(prefix)

  if (prefixWidth >= width) {
    lines.push(...wrapTextWithAnsi(prefix + text, width))
    return
  }

  const wrapped = wrapTextWithAnsi(text, width - prefixWidth)
  const continuationPrefix = " ".repeat(prefixWidth)

  for (let index = 0; index < wrapped.length; index++) {
    lines.push(`${index === 0 ? prefix : continuationPrefix}${wrapped[index]}`)
  }
}
