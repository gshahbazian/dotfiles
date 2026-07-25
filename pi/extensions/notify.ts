import type { ExtensionAPI } from "@earendil-works/pi-coding-agent"

// send a desktop notification via the OSC 777 escape sequence
export function notify(title: string, body: string): void {
  process.stdout.write(`\x1b]777;notify;${title};${body}\x07`)
}

export default function notifyWhenAgentSettles(pi: ExtensionAPI) {
  pi.on("agent_settled", () => {
    notify("pi completed its response", "Ready for your next request")
  })
}
