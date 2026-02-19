vim.filetype.add({
  filename = {},
  pattern = {
    [".*/%.vscode/.*%.json"] = "jsonc",
    [".*/zed/.*%.json"] = "jsonc",
  },
})
