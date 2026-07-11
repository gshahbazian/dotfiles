import type { ExtensionAPI } from "@earendil-works/pi-coding-agent"
import { Text } from "@earendil-works/pi-tui"
import { Type } from "typebox"
import {
  type Answer,
  promptWithQuestions,
  type Question,
  type QuestionOption,
} from "./shared/question-ui"

interface AskResult {
  questions: Question[]
  answers: Answer[]
  cancelled: boolean
}

interface LegacyAskResult {
  selection?: string | null
  selections?: string[]
  explanation?: string
  cancelled?: boolean
}

interface QuestionInput {
  question: string
  context?: string
  options: QuestionOption[]
  allowMultiple?: boolean
}

interface AskParams {
  question?: string
  context?: string
  options?: QuestionOption[]
  allowMultiple?: boolean
  questions?: QuestionInput[]
}

const OptionSchema = Type.Object({
  title: Type.String({ description: "Short option title" }),
  description: Type.Optional(
    Type.String({
      description: "Explanation of this option and its trade-offs",
    }),
  ),
})

const QuestionSchema = Type.Object({
  question: Type.String({ description: "The focused question to ask" }),
  context: Type.Optional(
    Type.String({
      description: "A concise summary of findings and trade-offs",
    }),
  ),
  options: Type.Array(OptionSchema, {
    minItems: 2,
    description: "The choices presented for this question",
  }),
  allowMultiple: Type.Optional(
    Type.Boolean({
      description:
        "Allow multiple selections for this question. Defaults to false",
    }),
  ),
})

function normalizeQuestion(input: QuestionInput): Question | undefined {
  const question = input.question.trim()
  const options = input.options
    .map((option) => ({
      title: option.title.trim(),
      description: option.description?.trim() || undefined,
    }))
    .filter((option) => option.title)

  if (!question || options.length < 2) return undefined

  return {
    question,
    context: input.context?.trim() || undefined,
    options,
    allowMultiple: input.allowMultiple ?? false,
  }
}

function normalizeQuestions(params: AskParams): Question[] {
  if (params.questions?.length) {
    return params.questions
      .map(normalizeQuestion)
      .filter((question): question is Question => question !== undefined)
  }

  if (!params.question || !params.options) return []

  const question = normalizeQuestion({
    question: params.question,
    context: params.context,
    options: params.options,
    allowMultiple: params.allowMultiple,
  })

  return question ? [question] : []
}

function formatAnswerContent(questions: Question[], answers: Answer[]): string {
  if (questions.length === 1) {
    const answer = answers[0]!
    const selection = answer.selections.join(", ")
    if (!answer.explanation) return `User selected: ${selection}`
    return `User selected: ${selection}\nUser explained: ${answer.explanation}`
  }

  const lines: string[] = []

  for (let index = 0; index < questions.length; index++) {
    const question = questions[index]!
    const answer = answers[index]!
    lines.push(`Question ${index + 1}: ${question.question}`)
    lines.push(`User selected: ${answer.selections.join(", ")}`)
    if (answer.explanation) lines.push(`User explained: ${answer.explanation}`)
    if (index < questions.length - 1) lines.push("")
  }

  return lines.join("\n")
}

export default function askUser(pi: ExtensionAPI) {
  pi.registerTool({
    name: "ask_user",
    label: "Ask User",
    description:
      "Ask the user one focused multiple-choice question or a short questionnaire of related, independent questions. Each question supports single-select or multi-select answers and an optional explanation. Prefer one question; use questions only when batching is genuinely more efficient.",
    promptSnippet:
      "Ask the human one focused multiple-choice question or a short related questionnaire",
    promptGuidelines: [
      "Use ask_user before making preference-sensitive decisions or assumptions that materially affect the implementation.",
      "Before calling ask_user, gather relevant context and summarize it in the context field.",
      "Prefer one focused question per ask_user call.",
      "Use ask_user questions only for 2-5 closely related, independent questions that can be answered without seeing earlier answers first.",
      "Do not batch dependent questions or unrelated decisions into one ask_user call.",
      "Set allowMultiple to true only when the user may choose more than one independent option.",
    ],
    executionMode: "sequential",
    parameters: Type.Object({
      question: Type.Optional(
        Type.String({
          description: "A single focused question. Use with options",
        }),
      ),
      context: Type.Optional(
        Type.String({ description: "Context for the single question" }),
      ),
      options: Type.Optional(
        Type.Array(OptionSchema, {
          minItems: 2,
          description: "Choices for the single question",
        }),
      ),
      allowMultiple: Type.Optional(
        Type.Boolean({
          description: "Allow multiple answers to the single question",
        }),
      ),
      questions: Type.Optional(
        Type.Array(QuestionSchema, {
          minItems: 2,
          maxItems: 5,
          description:
            "A short questionnaire. Use instead of question/options, only for related and independent questions",
        }),
      ),
    }),

    async execute(_toolCallId, rawParams, signal, onUpdate, ctx) {
      const params = rawParams as AskParams
      const questions = normalizeQuestions(params)

      if (questions.length === 0) {
        throw new Error(
          "ask_user requires either question with at least two options, or 2-5 valid questions",
        )
      }

      if (params.questions && questions.length !== params.questions.length) {
        throw new Error(
          "Every ask_user question requires non-empty text and at least two options",
        )
      }

      const cancelledDetails: AskResult = {
        questions,
        answers: [],
        cancelled: true,
      }

      if (signal?.aborted) {
        return {
          content: [
            { type: "text" as const, text: "User cancelled the question" },
          ],
          details: cancelledDetails,
        }
      }

      if (ctx.mode !== "tui") {
        return {
          content: [
            {
              type: "text" as const,
              text: "ask_user requires interactive TUI mode",
            },
          ],
          details: cancelledDetails,
        }
      }

      onUpdate?.({
        content: [{ type: "text", text: "Waiting for the user..." }],
        details: { questions, answers: [], cancelled: false },
      })

      const answers = await promptWithQuestions(ctx, questions, signal)

      if (!answers) {
        return {
          content: [
            { type: "text" as const, text: "User cancelled the question" },
          ],
          details: cancelledDetails,
        }
      }

      return {
        content: [
          {
            type: "text" as const,
            text: formatAnswerContent(questions, answers),
          },
        ],
        details: { questions, answers, cancelled: false } satisfies AskResult,
      }
    },

    renderCall(args, theme) {
      const questions = Array.isArray(args.questions) ? args.questions : []
      let text = theme.fg("toolTitle", theme.bold("ask_user "))

      if (questions.length > 0) {
        text += theme.fg("muted", `${questions.length} questions`)
        const labels = questions
          .map((question: QuestionInput) => question.question)
          .join(" • ")
        text += `\n${theme.fg("dim", `  ${labels}`)}`
        return new Text(text, 0, 0)
      }

      text += theme.fg("muted", args.question || "")
      const options = Array.isArray(args.options) ? args.options : []
      if (options.length > 0) {
        const titles = options
          .map((option: QuestionOption) => option.title)
          .join(", ")
        text += `\n${theme.fg("dim", `  ${titles}`)}`
      }
      if (args.allowMultiple) text += theme.fg("dim", " [multi-select]")

      return new Text(text, 0, 0)
    },

    renderResult(result, options, theme) {
      if (options.isPartial) {
        return new Text(theme.fg("muted", "Waiting for the user..."), 0, 0)
      }

      const details = result.details as
        (Partial<AskResult> & LegacyAskResult) | undefined
      if (!details || details.cancelled) {
        return new Text(theme.fg("warning", "Cancelled"), 0, 0)
      }

      if (details.questions?.length && details.answers?.length) {
        const lines = details.answers.map((answer, index) => {
          const prefix = details.answers!.length > 1 ? `Q${index + 1}: ` : ""
          let line = `${theme.fg("success", "✓ ")}${theme.fg("accent", prefix + answer.selections.join(", "))}`
          if (answer.explanation)
            line += `\n  ${theme.fg("muted", answer.explanation)}`
          return line
        })
        return new Text(lines.join("\n"), 0, 0)
      }

      const selections =
        details.selections ?? (details.selection ? [details.selection] : [])
      if (selections.length === 0) {
        return new Text(theme.fg("warning", "Cancelled"), 0, 0)
      }

      let text = `${theme.fg("success", "✓ ")}${theme.fg("accent", selections.join(", "))}`
      if (details.explanation)
        text += `\n${theme.fg("muted", details.explanation)}`
      return new Text(text, 0, 0)
    },
  })
}
