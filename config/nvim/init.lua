-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

vim.keymap.set("n", "<F4>", function()
  local ft = vim.bo.filetype
  local file = vim.fn.expand("%")
  local base = vim.fn.expand("%:r")

  local runners = {
    python = string.format('python3 "%s"', file),
    lua = string.format('lua "%s"', file),
    javascript = string.format('node "%s"', file),
    typescript = string.format('ts-node "%s"', file),

    -- AI Corrected Chain: rm only runs if the program exits successfully (status 0)
    c = string.format('gcc "%s" -o "%s" && ./"%s" && rm -f "%s"', file, base, base, base),
    cpp = string.format('g++ "%s" -o "%s" && ./"%s" && rm -f "%s"', file, base, base, base),
    rust = string.format('rustc "%s" -o "%s" && ./"%s" && rm -f "%s"', file, base, base, base),

    go = string.format('go run "%s"', file),
    java = string.format('javac "%s" && java "%s" && rm -f "%s.class"', file, base, base),
  }

  local cmd = runners[ft]

  if cmd then
    vim.cmd("silent write")

    -- Keep this: prevents vertical split spam
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.bo[buf].buftype == "terminal" then
        vim.api.nvim_win_close(win, true)
      end
    end

    vim.cmd("vsplit | terminal " .. cmd)
    vim.cmd("startinsert")
  else
    print("No runner for: " .. ft)
  end
end, { desc = "The Actually Perfect Runner" })
