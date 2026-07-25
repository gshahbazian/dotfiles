// send a desktop notification via the OSC 777 escape sequence
export function notify(title: string, body: string): void {
  process.stdout.write(`\x1b]777;notify;${title};${body}\x07`)
}
