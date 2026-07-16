import { getModel } from "@earendil-works/pi-ai/compat"
import type { ExtensionContext } from "@earendil-works/pi-coding-agent"

// Full "provider/model-id" used for OpenAI web search. Change to switch models.
const MODEL_NAME = "openai-codex/gpt-5.6-terra"

function parseModel(spec: string): {
  provider: "openai-codex" | "openai"
  id: string
} {
  const slash = spec.indexOf("/")
  const provider = spec.slice(0, slash)
  const id = spec.slice(slash + 1)
  if (provider !== "openai-codex" && provider !== "openai") {
    throw new Error(`Unsupported MODEL_NAME provider: "${provider}"`)
  }
  return { provider, id }
}

const MODEL = parseModel(MODEL_NAME)

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
  // getModel's params are typed against known literal ids; MODEL is developer-
  // controlled, so we pass it through and bail if the registry doesn't know it.
  const model = getModel(MODEL.provider as never, MODEL.id as never)
  if (!model) return undefined
  try {
    const auth = await ctx.modelRegistry.getApiKeyAndHeaders(model)
    if (auth.ok && auth.apiKey) {
      return {
        provider: MODEL.provider,
        apiKey: auth.apiKey,
        model: MODEL.id,
        headers: auth.headers ?? {},
      }
    }
  } catch {
    // No usable credential for this model.
  }
  return undefined
}

// Codex-issued JWTs carry an OpenAI auth claim; API keys do not.
function decodeJwtPayload(token: string): Record<string, unknown> | null {
  const parts = token.split(".")
  if (parts.length !== 3 || !parts[1]) return null
  try {
    const b64 = parts[1]
      .replace(/-/g, "+")
      .replace(/_/g, "/")
      .padEnd(Math.ceil(parts[1].length / 4) * 4, "=")
    const parsed = JSON.parse(Buffer.from(b64, "base64").toString("utf8"))
    if (parsed && typeof parsed === "object") {
      return parsed as Record<string, unknown>
    }
    return null
  } catch {
    return null
  }
}

export function isCodexJwt(token: string): boolean {
  return !!decodeJwtPayload(token)?.["https://api.openai.com/auth"]
}

export function extractAccountId(token: string): string | undefined {
  const auth = decodeJwtPayload(token)?.["https://api.openai.com/auth"]
  if (!auth || typeof auth !== "object") return undefined
  const id = (auth as Record<string, unknown>).chatgpt_account_id
  if (typeof id !== "string") return undefined
  const trimmed = id.trim()
  if (trimmed.length === 0) return undefined
  return trimmed
}
