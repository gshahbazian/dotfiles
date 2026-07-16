import { getModel } from "@earendil-works/pi-ai/compat"
import type { ExtensionContext } from "@earendil-works/pi-coding-agent"

// Model used for web search. Change to switch models.
const PROVIDER: "openai-codex" | "openai" = "openai-codex"
const MODEL_ID = "gpt-5.6-terra"

const AUTH_CLAIM = "https://api.openai.com/auth"

export const AUTH_HELP =
  "OpenAI web search unavailable. Use /login to sign in with a Codex subscription."

export interface OpenAIAuth {
  provider: "openai-codex" | "openai"
  apiKey: string
  model: string
  headers: Record<string, string>
}

// Auth comes solely from pi's model registry (i.e. your `/login` credential).
export async function resolveOpenAIAuth(
  ctx: ExtensionContext,
): Promise<OpenAIAuth | undefined> {
  // getModel is typed against known literal ids; ours is developer-controlled.
  const model = getModel(PROVIDER as never, MODEL_ID as never)
  if (!model) return undefined

  try {
    const auth = await ctx.modelRegistry.getApiKeyAndHeaders(model)
    if (!auth.ok || !auth.apiKey) return undefined
    return {
      provider: PROVIDER,
      apiKey: auth.apiKey,
      model: MODEL_ID,
      headers: auth.headers ?? {},
    }
  } catch {
    return undefined
  }
}

function decodeJwtPayload(token: string): Record<string, unknown> | null {
  const parts = token.split(".")
  if (parts.length !== 3 || !parts[1]) return null

  try {
    const parsed = JSON.parse(Buffer.from(parts[1], "base64url").toString())
    if (parsed && typeof parsed === "object") {
      return parsed as Record<string, unknown>
    }
  } catch {
    // Not a JWT.
  }
  return null
}

// Codex-issued JWTs carry an OpenAI auth claim; API keys do not.
export function isCodexJwt(token: string): boolean {
  return !!decodeJwtPayload(token)?.[AUTH_CLAIM]
}

export function extractAccountId(token: string): string | undefined {
  const auth = decodeJwtPayload(token)?.[AUTH_CLAIM]
  if (!auth || typeof auth !== "object") return undefined

  const id = (auth as Record<string, unknown>).chatgpt_account_id
  if (typeof id !== "string" || !id.trim()) return undefined
  return id.trim()
}
