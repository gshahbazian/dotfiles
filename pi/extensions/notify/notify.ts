import type { ExtensionAPI } from "@earendil-works/pi-coding-agent"
import { notify } from "../shared/notify"

export default function notifyWhenAgentSettles(pi: ExtensionAPI) {
  pi.on("agent_settled", () => {
    notify("pi completed its response", "Ready for your next request")
  })
}
