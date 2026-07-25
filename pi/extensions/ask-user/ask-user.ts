import type {
  ExtensionAPI,
  ExtensionContext,
  Theme,
} from "@earendil-works/pi-coding-agent"
import {
  Editor,
  type EditorTheme,
  type Focusable,
  Key,
  type KeybindingsManager,
  matchesKey,
  Text,
  type TUI,
  truncateToWidth,
} from "@earendil-works/pi-tui"
import { Type } from "typebox"
import { notify } from "../shared/notify"
import { addWrappedLine } from "../shared/wrap"

interface QuestionOption {
  title: string
  description?: string
}

interface Question {
  question: string
  context?: string
  options: QuestionOption[]
  allowMultiple: boolean
}

interface Answer {
  selections: string[]
  explanation?: string
}

function createEditorTheme(theme: Theme): EditorTheme {
  return {
    borderColor: (text: string) => theme.fg("accent", text),
    selectList: {
      selectedPrefix: (text: string) => theme.fg("accent", text),
      selectedText: (text: string) => theme.fg("accent", text),
      description: (text: string) => theme.fg("muted", text),
      scrollInfo: (text: string) => theme.fg("dim", text),
      noMatch: (text: string) => theme.fg("warning", text),
    },
  }
}

class AskUserComponent implements Focusable {
  private questionIndex = 0
  private reviewing = false
  private explaining = false
  private readonly selectedIndices: number[]
  private readonly checkedIndices: Array<Set<number>>
  private readonly explanationDrafts: string[]
  private readonly answers: Array<Answer | undefined>
  private cachedWidth?: number
  private cachedLines?: string[]
  private readonly editor: Editor
  private _focused = false

  get focused(): boolean {
    return this._focused
  }

  set focused(value: boolean) {
    this._focused = value
    this.editor.focused = value && this.explaining
  }

  constructor(
    private readonly questions: Question[],
    private readonly tui: TUI,
    private readonly theme: Theme,
    private readonly keybindings: KeybindingsManager,
    private readonly done: (result: Answer[] | null) => void,
  ) {
    this.selectedIndices = questions.map(() => 0)
    this.checkedIndices = questions.map(() => new Set<number>())
    this.explanationDrafts = questions.map(() => "")
    this.answers = questions.map(() => undefined)

    this.editor = new Editor(tui, createEditorTheme(theme))
    this.editor.disableSubmit = true
    this.editor.onChange = () => this.refresh()
  }

  private refresh(): void {
    this.invalidate()
    this.tui.requestRender()
  }

  private currentQuestion(): Question {
    return this.questions[this.questionIndex]!
  }

  private selectedIndex(): number {
    return this.selectedIndices[this.questionIndex]!
  }

  private checked(): Set<number> {
    return this.checkedIndices[this.questionIndex]!
  }

  private selectedOptions(): QuestionOption[] {
    const question = this.currentQuestion()
    const checked = this.checked()

    if (!question.allowMultiple || checked.size === 0) {
      return [question.options[this.selectedIndex()]!]
    }

    return [...checked]
      .sort((left, right) => left - right)
      .map((index) => question.options[index]!)
  }

  private toggleSelectedOption(): void {
    const checked = this.checked()
    const selectedIndex = this.selectedIndex()

    if (checked.has(selectedIndex)) {
      checked.delete(selectedIndex)
    } else {
      checked.add(selectedIndex)
    }

    this.refresh()
  }

  private moveSelection(offset: number): void {
    const optionCount = this.currentQuestion().options.length
    const nextIndex =
      (this.selectedIndex() + offset + optionCount) % optionCount
    this.selectedIndices[this.questionIndex] = nextIndex
    this.refresh()
  }

  private navigateToQuestion(index: number): void {
    if (index < 0 || index >= this.questions.length) return

    if (this.explaining) this.saveExplanationDraft()
    this.reviewing = false
    this.explaining = false
    this.editor.focused = false
    this.questionIndex = index
    this.refresh()
  }

  private enterExplanation(): void {
    this.explaining = true
    this.editor.setText(this.explanationDrafts[this.questionIndex] ?? "")
    this.editor.focused = this._focused
    this.refresh()
  }

  private saveExplanationDraft(): void {
    this.explanationDrafts[this.questionIndex] = this.editor.getText()
  }

  private leaveExplanation(): void {
    this.saveExplanationDraft()
    this.explaining = false
    this.editor.focused = false
    this.refresh()
  }

  private saveCurrentAnswer(explanation?: string): void {
    const normalizedExplanation = explanation?.trim() || undefined
    this.explanationDrafts[this.questionIndex] = explanation ?? ""
    this.answers[this.questionIndex] = {
      selections: this.selectedOptions().map((option) => option.title),
      explanation: normalizedExplanation,
    }
  }

  private advanceAfterAnswer(): void {
    this.explaining = false
    this.editor.focused = false

    if (this.questions.length === 1) {
      this.done(this.answers as Answer[])
      return
    }

    if (this.questionIndex < this.questions.length - 1) {
      this.questionIndex++
      this.refresh()
      return
    }

    this.reviewing = true
    this.refresh()
  }

  private answerCurrentQuestion(explanation?: string): void {
    this.saveCurrentAnswer(explanation)
    this.advanceAfterAnswer()
  }

  private allAnswered(): boolean {
    return this.answers.every((answer) => answer !== undefined)
  }

  private submitQuestionnaire(): void {
    if (this.allAnswered()) {
      this.done(this.answers as Answer[])
      return
    }

    const firstUnanswered = this.answers.findIndex(
      (answer) => answer === undefined,
    )
    this.navigateToQuestion(firstUnanswered)
  }

  private handleReviewInput(data: string): void {
    if (matchesKey(data, Key.escape) || matchesKey(data, Key.left)) {
      this.navigateToQuestion(this.questions.length - 1)
      return
    }

    if (matchesKey(data, Key.ctrl("c"))) {
      this.done(null)
      return
    }

    if (this.keybindings.matches(data, "tui.select.confirm")) {
      this.submitQuestionnaire()
    }
  }

  private handleExplanationInput(data: string): void {
    if (matchesKey(data, Key.shift("tab")) || matchesKey(data, Key.escape)) {
      this.leaveExplanation()
      return
    }

    if (this.keybindings.matches(data, "tui.input.submit")) {
      this.answerCurrentQuestion(this.editor.getText())
      return
    }

    this.editor.handleInput(data)
    this.refresh()
  }

  handleInput(data: string): void {
    if (this.reviewing) {
      this.handleReviewInput(data)
      return
    }

    if (this.explaining) {
      this.handleExplanationInput(data)
      return
    }

    if (this.keybindings.matches(data, "tui.select.cancel")) {
      this.done(null)
      return
    }

    if (matchesKey(data, Key.left)) {
      this.navigateToQuestion(this.questionIndex - 1)
      return
    }

    if (matchesKey(data, Key.right)) {
      if (
        this.questionIndex === this.questions.length - 1 &&
        this.questions.length > 1
      ) {
        this.reviewing = true
        this.refresh()
        return
      }

      this.navigateToQuestion(this.questionIndex + 1)
      return
    }

    if (this.keybindings.matches(data, "tui.select.up")) {
      this.moveSelection(-1)
      return
    }

    if (this.keybindings.matches(data, "tui.select.down")) {
      this.moveSelection(1)
      return
    }

    if (matchesKey(data, Key.tab)) {
      this.enterExplanation()
      return
    }

    if (this.currentQuestion().allowMultiple && matchesKey(data, Key.space)) {
      this.toggleSelectedOption()
      return
    }

    const number = Number.parseInt(data, 10)
    const optionCount = this.currentQuestion().options.length
    if (number >= 1 && number <= Math.min(optionCount, 9)) {
      this.selectedIndices[this.questionIndex] = number - 1
      if (this.currentQuestion().allowMultiple) {
        this.toggleSelectedOption()
        return
      }

      this.refresh()
      return
    }

    if (this.keybindings.matches(data, "tui.select.confirm")) {
      this.answerCurrentQuestion()
    }
  }

  private renderProgress(lines: string[], width: number): void {
    if (this.questions.length === 1) return

    const indicators = this.questions.map((_, index) => {
      const label = `${index + 1}`
      if (index === this.questionIndex && !this.reviewing) {
        return this.theme.bg("selectedBg", this.theme.fg("text", ` ${label} `))
      }
      if (this.answers[index]) return this.theme.fg("success", `●${label}`)
      return this.theme.fg("dim", `○${label}`)
    })

    const reviewLabel = this.reviewing
      ? this.theme.bg("selectedBg", this.theme.fg("text", " Review "))
      : this.theme.fg("dim", "Review")

    addWrappedLine(
      lines,
      " ",
      `${indicators.join("  ")}  ${reviewLabel}`,
      width,
    )
    lines.push("")
  }

  private renderOptions(lines: string[], width: number): void {
    const question = this.currentQuestion()
    const selectedIndex = this.selectedIndex()
    const checked = this.checked()

    for (let index = 0; index < question.options.length; index++) {
      const option = question.options[index]!
      const selected = index === selectedIndex
      const pointer = selected ? this.theme.fg("accent", "› ") : "  "
      const checkbox = question.allowMultiple
        ? `${checked.has(index) ? this.theme.fg("success", "[✓]") : this.theme.fg("dim", "[ ]")} `
        : ""
      const title = `${index + 1}. ${checkbox}${option.title}`
      const styledTitle = selected
        ? this.theme.fg("accent", this.theme.bold(title))
        : this.theme.fg("text", title)

      addWrappedLine(lines, pointer, styledTitle, width)

      if (option.description) {
        addWrappedLine(
          lines,
          "     ",
          this.theme.fg("muted", option.description),
          width,
        )
      }
    }
  }

  private renderExplanation(lines: string[], width: number): void {
    const selection = this.selectedOptions()
      .map((option) => option.title)
      .join(", ")

    lines.push("")
    addWrappedLine(
      lines,
      " ",
      this.theme.fg(
        "accent",
        this.theme.bold(`Explain "${selection}" (optional)`),
      ),
      width,
    )

    for (const line of this.editor.render(Math.max(1, width - 2))) {
      lines.push(truncateToWidth(` ${line}`, width, ""))
    }

    lines.push("")
    addWrappedLine(
      lines,
      " ",
      this.theme.fg(
        "dim",
        "Enter save/next • Shift+Enter newline • Shift+Tab/Esc choices",
      ),
      width,
    )
  }

  private renderQuestion(lines: string[], width: number): void {
    const question = this.currentQuestion()
    const title =
      this.questions.length === 1
        ? "Question"
        : `Question ${this.questionIndex + 1} of ${this.questions.length}`

    addWrappedLine(
      lines,
      " ",
      this.theme.fg("accent", this.theme.bold(title)),
      width,
    )
    addWrappedLine(
      lines,
      " ",
      this.theme.fg("text", this.theme.bold(question.question)),
      width,
    )

    if (question.context) {
      lines.push("")
      addWrappedLine(
        lines,
        " ",
        this.theme.fg("muted", `Context: ${question.context}`),
        width,
      )
    }

    lines.push("")
    this.renderOptions(lines, width)

    if (this.explaining) {
      this.renderExplanation(lines, width)
      return
    }

    lines.push("")
    const selectionControls = question.allowMultiple
      ? "↑↓ choose • Space toggle • Enter save/next • Tab explain"
      : "↑↓ choose • Enter save/next • Tab explain"
    const navigationControls =
      this.questions.length > 1 ? " • ←→ questions/review" : ""
    addWrappedLine(
      lines,
      " ",
      this.theme.fg(
        "dim",
        `${selectionControls}${navigationControls} • Esc cancel`,
      ),
      width,
    )
  }

  private renderReview(lines: string[], width: number): void {
    addWrappedLine(
      lines,
      " ",
      this.theme.fg("accent", this.theme.bold("Review answers")),
      width,
    )
    lines.push("")

    for (let index = 0; index < this.questions.length; index++) {
      const question = this.questions[index]!
      const answer = this.answers[index]
      const marker = answer
        ? this.theme.fg("success", "✓")
        : this.theme.fg("warning", "○")
      addWrappedLine(
        lines,
        ` ${marker} `,
        this.theme.fg("text", question.question),
        width,
      )

      if (answer) {
        addWrappedLine(
          lines,
          "    ",
          this.theme.fg("accent", answer.selections.join(", ")),
          width,
        )
        if (answer.explanation) {
          addWrappedLine(
            lines,
            "    ",
            this.theme.fg("muted", answer.explanation),
            width,
          )
        }
      } else {
        addWrappedLine(
          lines,
          "    ",
          this.theme.fg("warning", "Unanswered"),
          width,
        )
      }

      if (index < this.questions.length - 1) lines.push("")
    }

    lines.push("")
    const submitHint = this.allAnswered()
      ? "Enter submit"
      : "Enter go to first unanswered"
    addWrappedLine(
      lines,
      " ",
      this.theme.fg("dim", `${submitHint} • ←/Esc back • Ctrl+C cancel`),
      width,
    )
  }

  render(width: number): string[] {
    if (this.cachedLines && this.cachedWidth === width) return this.cachedLines

    const renderWidth = Math.max(1, width)
    const lines: string[] = [this.theme.fg("accent", "─".repeat(renderWidth))]

    this.renderProgress(lines, renderWidth)

    if (this.reviewing) {
      this.renderReview(lines, renderWidth)
    } else {
      this.renderQuestion(lines, renderWidth)
    }

    lines.push(this.theme.fg("accent", "─".repeat(renderWidth)))

    this.cachedWidth = width
    this.cachedLines = lines
    return lines
  }

  invalidate(): void {
    this.cachedWidth = undefined
    this.cachedLines = undefined
    this.editor.invalidate()
  }
}

async function promptWithQuestions(
  ctx: ExtensionContext,
  questions: Question[],
  signal?: AbortSignal,
): Promise<Answer[] | null> {
  return ctx.ui.custom<Answer[] | null>((tui, theme, keybindings, done) => {
    if (signal) {
      signal.addEventListener("abort", () => done(null), { once: true })
    }

    return new AskUserComponent(questions, tui, theme, keybindings, done)
  })
}

interface AskResult {
  questions: Question[]
  answers: Answer[]
  cancelled: boolean
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

      const notifyBody = questions[0]?.question ?? "Your input is needed"
      notify("pi needs your input", notifyBody)

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

      // Sessions are replayed from disk, so tolerate a details shape this
      // version didn't write.
      const details = result.details as Partial<AskResult> | undefined
      const answers = details?.answers
      if (details?.cancelled || !answers?.length) {
        return new Text(theme.fg("warning", "Cancelled"), 0, 0)
      }

      const lines = answers.map((answer, index) => {
        const prefix = answers.length > 1 ? `Q${index + 1}: ` : ""
        let line = `${theme.fg("success", "✓ ")}${theme.fg("accent", prefix + answer.selections.join(", "))}`
        if (answer.explanation) {
          line += `\n  ${theme.fg("muted", answer.explanation)}`
        }
        return line
      })
      return new Text(lines.join("\n"), 0, 0)
    },
  })
}
