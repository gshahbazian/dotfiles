rex.bind("ctrl+l", "com.superlogical.terminal.clear")

rex.mode("prefix", { exclusive = true })
rex.bind("ctrl+b", "client.mode.enter", { name = "prefix", once = true })

rex.bind("prefix/h", "pane.focus", { direction = "left" })
rex.bind("prefix/j", "pane.focus", { direction = "down" })
rex.bind("prefix/k", "pane.focus", { direction = "up" })
rex.bind("prefix/l", "pane.focus", { direction = "right" })
rex.bind("prefix/z", "pane.zoom")

-- Press Ctrl+B twice to send it to the terminal.
rex.bind("prefix/ctrl+b", "pane.send_key", { key = "ctrl+b" })
