return {
  -- 1. Install and Configure the Theme
  {
    "bluz71/vim-moonfly-colors",
    name = "moonfly",
    lazy = false, -- Load immediately
    priority = 1000, -- Load before everything else to prevent flashes
    config = function()
      -- === Core Settings ===
      vim.g.moonflyTransparent = false -- Keep false for deep black contrast
      vim.g.moonflyItalics = true -- Italicize comments and keywords
      vim.g.moonflyUndercurls = true -- Wavy red lines for syntax errors
      vim.g.moonflyVirtualTextColor = true -- Brighten up "Inlay Hints" (LSP types)

      -- === UI & Terminal ===
      vim.g.moonflyWinSeparator = 2 -- Thick split lines (Great for your <F4> runner)
      vim.g.moonflyNormalFloat = true -- distinct background for floating windows
      vim.g.moonflyTerminalColors = true -- Syncs your internal terminal colors with the theme

      -- === The "Perfect" Highlighter Overrides ===
      -- This ensures specific code elements POP for code checking.
      -- We use an autocmd so these apply every time the colorscheme reloads.
      vim.api.nvim_create_autocmd("ColorScheme", {
        pattern = "moonfly",
        callback = function()
          -- Functions: Bright Blue & Italic (e.g., main, printf, print)
          vim.api.nvim_set_hl(0, "Function", { fg = "#82aaff", italic = true })

          -- Keywords: Purple & Italic (e.g., return, if, else, for)
          vim.api.nvim_set_hl(0, "Keyword", { fg = "#c792ea", italic = true })

          -- Comments: Slightly brighter Grey so you don't miss them
          vim.api.nvim_set_hl(0, "Comment", { fg = "#7e8294", italic = true })

          -- Strings: Bright Green (Clear separation from variables)
          vim.api.nvim_set_hl(0, "String", { fg = "#c3e88d" })
        end,
      })

      -- Load the theme finally
      vim.cmd([[colorscheme moonfly]])
    end,
  },

  -- 2. Tell LazyVim to use it as default
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "moonfly",
    },
  },
}
