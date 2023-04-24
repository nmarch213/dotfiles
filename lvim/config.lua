-- plugins
-- define the plugins so that the settings below can be used
lvim.plugins = {
  { 'Mofiqul/dracula.nvim' },
  { 'prettier/vim-prettier' },
  { "tpope/vim-surround" },
  { "leafgarland/typescript-vim" },
  { "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    config = function()
      require("copilot").setup({
        suggestion = {
          auto_trigger = true
        }
      })
    end, },
  { "zbirenbaum/copilot-cmp",
    after = { "copilot.lua", "nvim-cmp" },
  },
  {
    "folke/trouble.nvim",
    requires = "kyazdani42/nvim-web-devicons",
    config = function()
      require("trouble").setup {
        -- your configuration comes here
        -- or leave it empty to use the default settings
        -- refer to the configuration section below
      }
    end
  }
}

lvim.autocommands.custom_groups = {
  { "BufWritePre", "*.js,*.jsx,*.ts,*.tsx,*.css,*.scss,*.html,*.json,*.md", "PrettierAsync" },
}

-- Copilot settings
lvim.builtin.cmp.formatting.source_names["copilot"] = "(Copilot)"
table.insert(lvim.builtin.cmp.sources, 1, { name = "copilot" })

-- general
lvim.log.level = "warn"
lvim.format_on_save.enabled = true
lvim.colorscheme = "dracula"
vim.opt.relativenumber = true
vim.opt.guifont = "10"

-- keymappings [view all the defaults by pressing <leader>Lk]
lvim.leader = "space"
lvim.keys.normal_mode["<C-s>"] = ":w<cr>" -- save with ctrl+s
lvim.keys.normal_mode["<T-j>"] = ":m .+1<CR>==" -- move line down with alt+k
lvim.keys.normal_mode["<T-k>"] = ":m .-2<CR>==" -- move line up with alt+j
lvim.keys.normal_mode["<leader>tt"] = "<cmd>TroubleToggle<cr>" -- list troubles in file

lvim.keys.normal_mode["<leader>p"] = ":PrettierAsync<CR>" -- prettier

lvim.keys.normal_mode["|"] = ":vsplit<CR>" -- split window vertically
lvim.keys.normal_mode["<Leader>bo"] = ':%bd!|e #|bd #|normal`"<CR>'

-- built in lunarvim plugin config
lvim.builtin.alpha.active = true
lvim.builtin.alpha.mode = "dashboard"
lvim.builtin.terminal.active = true
lvim.builtin.nvimtree.setup.view.side = "right"
lvim.builtin.nvimtree.setup.renderer.icons.show.git = false
-- if you don't want all the parsers change this to a table of the ones you want
lvim.builtin.treesitter.ensure_installed = {
  "bash",
  "c",
  "javascript",
  "json",
  "lua",
  "python",
  "typescript",
  "tsx",
  "css",
  "rust",
  "java",
  "yaml",
}
lvim.builtin.treesitter.ignore_install = { "haskell" }
lvim.builtin.treesitter.highlight.enable = true


-- setup custom linters/formatters
local linters = require "lvim.lsp.null-ls.linters"

linters.setup {
  { command = "eslint", filetypes = { "typescript", "typescriptreact", "javascript" } }
}

local formatters = require "lvim.lsp.null-ls.formatters"

formatters.setup {
  { command = "prettier", filetypes = { "typescript", "typescriptreact", "javascript", "json", "css", "scss", "html", "markdown" } }
}
