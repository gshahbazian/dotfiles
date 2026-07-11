import { complete, type UserMessage } from "@earendil-works/pi-ai/compat"
import {
  BorderedLoader,
  type ExtensionAPI,
  type ExtensionContext,
} from "@earendil-works/pi-coding-agent"
import {
  type Answer,
  promptWithQuestions,
  type Question,
  type QuestionOption,
} from "./shared/question-ui"

// inspired by
// https://github.com/dmmulroy/.dotfiles/blob/main/home/.pi/agent/extensions/answer.ts

interface ExtractionPayload {
  questions?: Array<{
    question?: unknown
    context?: unknown
    options?: unknown
    allowMultiple?: unknown
  }>
}

type ExtractionOutcome =
  | { type: "success"; questions: Question[] }
  | { type: "cancelled" }
  | { type: "error"; message: string }

const SYSTEM_PROMPT = `You extract unanswered questions from the assistant's latest message and turn them into a concise multiple-choice questionnaire.

Return exactly one JSON object:
{
  "questions": [
    {
      "question": "A self-contained question",
      "context": "Optional concise context needed to answer",
      "options": [
        { "title": "Short choice", "description": "Optional trade-off or detail" }
      ],
      "allowMultiple": false
    }
  ]
}

Rules:
- Extract only questions that still require an answer from the user.
- Return at most 5 questions, in their original order.
- Preserve explicit answer choices from the assistant when present.
- If a question has no explicit choices, generate concise, sensible choices that cover the likely answers.
- Every question must have at least two distinct choices.
- Every question must include a final option titled exactly "Other / something else" unless an equivalent Other option already exists.
- Set allowMultiple to true only when choosing several independent options makes sense.
- Keep each question self-contained and preserve answer-relevant constraints, names, and requested formats.
- Put supporting detail in context rather than bloating the question.
- Do not invent factual claims or recommendations in generated choices.
- Do not include questions that the assistant already answered itself.
- If there are no unanswered questions, return {"questions":[]}.
- Do not add markdown fences or commentary outside the JSON object.`

function getTextParts(
  content: Array<{ type: string; text?: string }>,
): string[] {
  return content
    .filter(
      (part): part is { type: "text"; text: string } =>
        part.type === "text" && typeof part.text === "string",
    )
    .map((part) => part.text)
}

function findLastCompletedAssistantMessage(ctx: ExtensionContext): {
  text?: string
  skippedIncomplete: boolean
} {
  const branch = ctx.sessionManager.getBranch()
  let skippedIncomplete = false

  for (let index = branch.length - 1; index >= 0; index--) {
    const entry = branch[index]!
    if (entry.type !== "message") continue

    const message = entry.message
    if (!("role" in message) || message.role !== "assistant") continue

    if (message.stopReason !== "stop") {
      skippedIncomplete = true
      continue
    }

    const text = getTextParts(message.content).join("\n").trim()
    if (text) return { text, skippedIncomplete }
  }

  return { skippedIncomplete }
}

function getJsonCandidates(text: string): string[] {
  const candidates = new Set<string>()
  const trimmed = text.trim()
  if (trimmed) candidates.add(trimmed)

  for (const match of text.matchAll(/```(?:json)?\s*([\s\S]*?)```/gi)) {
    const candidate = match[1]?.trim()
    if (candidate) candidates.add(candidate)
  }

  const firstBrace = text.indexOf("{")
  const lastBrace = text.lastIndexOf("}")
  if (firstBrace !== -1 && lastBrace > firstBrace) {
    candidates.add(text.slice(firstBrace, lastBrace + 1))
  }

  return [...candidates]
}

function normalizeOption(value: unknown): QuestionOption | undefined {
  if (typeof value === "string") {
    const title = value.trim()
    return title ? { title } : undefined
  }

  if (!value || typeof value !== "object") return undefined

  const option = value as { title?: unknown; description?: unknown }
  if (typeof option.title !== "string" || !option.title.trim()) return undefined

  const description =
    typeof option.description === "string"
      ? option.description.trim() || undefined
      : undefined

  return {
    title: option.title.trim(),
    description,
  }
}

function hasOtherOption(options: QuestionOption[]): boolean {
  return options.some((option) =>
    /\b(other|something else|none of (these|the above))\b/i.test(option.title),
  )
}

function normalizeOptions(value: unknown): QuestionOption[] {
  if (!Array.isArray(value)) return []

  const seen = new Set<string>()
  const options: QuestionOption[] = []

  for (const item of value) {
    const option = normalizeOption(item)
    if (!option) continue

    const key = option.title.toLowerCase()
    if (seen.has(key)) continue

    seen.add(key)
    options.push(option)
  }

  if (!hasOtherOption(options)) {
    options.push({
      title: "Other / something else",
      description: "Select this and press Tab to provide your own answer.",
    })
  }

  return options
}

function normalizePayload(payload: ExtractionPayload): Question[] {
  if (!Array.isArray(payload.questions)) return []

  const questions: Question[] = []

  for (const item of payload.questions.slice(0, 5)) {
    if (typeof item.question !== "string" || !item.question.trim()) continue

    const options = normalizeOptions(item.options)
    if (options.length < 2) continue

    const context =
      typeof item.context === "string"
        ? item.context.trim() || undefined
        : undefined

    questions.push({
      question: item.question.trim(),
      context,
      options,
      allowMultiple: item.allowMultiple === true,
    })
  }

  return questions
}

function parseExtraction(text: string): ExtractionOutcome {
  for (const candidate of getJsonCandidates(text)) {
    try {
      const payload = JSON.parse(candidate) as ExtractionPayload
      if (payload && Array.isArray(payload.questions)) {
        return { type: "success", questions: normalizePayload(payload) }
      }
    } catch {
      // Try the next candidate.
    }
  }

  return {
    type: "error",
    message: "Question extraction returned invalid JSON.",
  }
}

function buildAnswerMessage(questions: Question[], answers: Answer[]): string {
  const lines = ["Here are my answers to your questions:", ""]

  for (let index = 0; index < questions.length; index++) {
    const question = questions[index]!
    const answer = answers[index]!

    lines.push(`Q${index + 1}: ${question.question}`)
    lines.push(`Selected: ${answer.selections.join(", ")}`)
    if (answer.explanation) lines.push(`Explanation: ${answer.explanation}`)
    if (index < questions.length - 1) lines.push("")
  }

  return lines.join("\n")
}

export default function answer(pi: ExtensionAPI) {
  const answerHandler = async (ctx: ExtensionContext) => {
    if (ctx.mode !== "tui") {
      ctx.ui.notify("answer requires interactive TUI mode", "error")
      return
    }

    if (!ctx.model) {
      ctx.ui.notify("No model selected", "error")
      return
    }

    const { text, skippedIncomplete } = findLastCompletedAssistantMessage(ctx)
    if (!text) {
      const message = skippedIncomplete
        ? "No completed assistant message found yet"
        : "No assistant messages found"
      ctx.ui.notify(message, "error")
      return
    }

    if (skippedIncomplete) {
      ctx.ui.notify("Using the last completed assistant message", "warning")
    }

    const extraction = await ctx.ui.custom<ExtractionOutcome>(
      (tui, theme, _keybindings, done) => {
        const loader = new BorderedLoader(
          tui,
          theme,
          `Extracting questions using ${ctx.model!.provider}/${ctx.model!.id}...`,
        )
        loader.onAbort = () => done({ type: "cancelled" })

        const extract = async (): Promise<ExtractionOutcome> => {
          const auth = await ctx.modelRegistry.getApiKeyAndHeaders(ctx.model!)
          if (!auth.ok) return { type: "error", message: auth.error }

          const userMessage: UserMessage = {
            role: "user",
            content: [{ type: "text", text }],
            timestamp: Date.now(),
          }

          const response = await complete(
            ctx.model!,
            { systemPrompt: SYSTEM_PROMPT, messages: [userMessage] },
            {
              apiKey: auth.apiKey,
              headers: auth.headers,
              env: auth.env,
              signal: loader.signal,
            },
          )

          if (response.stopReason === "aborted") return { type: "cancelled" }

          const responseText = getTextParts(response.content).join("\n").trim()
          if (!responseText) {
            return {
              type: "error",
              message: "Question extraction returned no content.",
            }
          }

          return parseExtraction(responseText)
        }

        extract()
          .then(done)
          .catch((error) => {
            const message =
              error instanceof Error ? error.message : String(error)
            done({ type: "error", message })
          })

        return loader
      },
    )

    if (extraction.type === "cancelled") {
      ctx.ui.notify("Cancelled", "info")
      return
    }

    if (extraction.type === "error") {
      ctx.ui.notify(extraction.message, "error")
      return
    }

    if (extraction.questions.length === 0) {
      ctx.ui.notify(
        "No unanswered questions found in the last assistant message",
        "info",
      )
      return
    }

    const answers = await promptWithQuestions(ctx, extraction.questions)
    if (!answers) {
      ctx.ui.notify("Cancelled", "info")
      return
    }

    const answerMessage = buildAnswerMessage(extraction.questions, answers)
    if (ctx.isIdle()) {
      pi.sendUserMessage(answerMessage)
      return
    }

    pi.sendUserMessage(answerMessage, { deliverAs: "followUp" })
    ctx.ui.notify("Answers queued as a follow-up message", "info")
  }

  pi.registerCommand("answer", {
    description:
      "Extract questions from the last assistant response and answer them interactively",
    handler: async (_args, ctx) => answerHandler(ctx),
  })

  pi.registerShortcut("ctrl+.", {
    description:
      "Extract and answer questions from the last assistant response",
    handler: answerHandler,
  })
}
