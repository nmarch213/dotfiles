-- plugins
-- define the plugins so that the settings below can be used
lvim.plugins = {
  -- { 'Mofiqul/dracula.nvim' },
  {
    'catppuccin/nvim',
    config = function()
      require("catppuccin").setup {
        flavour = "mocha",
        transparent_background = true

      }
    end
  },
  {
    "akinsho/bufferline.nvim",
    after = "catppuccin",
    config = function()
      require("bufferline").setup {
        highlights = require("catppuccin.groups.integrations.bufferline").get()
      }
    end
  },
  { "tpope/vim-surround" },
  { "mbbill/undotree" },
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    config = function()
      require("copilot").setup({
        suggestion = { enabled = false },
        panel = { enabled = false },
      })
    end,
  },
  {
    "zbirenbaum/copilot-cmp",
    config = function()
      require("copilot_cmp").setup(
        {
          fix_pairs = true,
        }
      )
    end
  },
  {
    "folke/trouble.nvim",
    config = function()
      require("trouble").setup {
        -- your configuration comes here
        -- or leave it empty to use the default settings
        -- refer to the configuration section below
      }
    end
  },
  {
    "epwalsh/obsidian.nvim",
    lazy = true,
    event = "BufReadPre /Users/nicholasmarch/Library/**",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "hrsh7th/nvim-cmp",
      "nvim-telescope/telescope.nvim",
    },
    opts = {
      dir = "/Users/nicholasmarch/Library/Mobile Documents/iCloud~md~obsidian/Documents/Brain",
      notes_subdir = "notes",
      daily_notes = {
        folder = "notes/daily",
      },
      completion = {
        nvim_cmp = true,
        min_chars = 2,
        new_notes_location = "notes_subdir"
      },
    },
    config = function(_, opts)
      require("obsidian").setup(opts)
      -- Optional, override the 'gf' keymap to utilize Obsidian's search functionality.
      -- see also: 'follow_url_func' config option above.
      vim.keymap.set("n", "gf", function()
        if require("obsidian").util.cursor_on_markdown_link() then
          return "<cmd>ObsidianFollowLink<CR>"
        else
          return "gf"
        end
      end, { noremap = false, expr = true })
    end,
  }
}

-- Copilot settings
lvim.builtin.cmp.formatting.source_names["copilot"] = "(Copilot)"
table.insert(lvim.builtin.cmp.sources, 1, { name = "copilot" })

-- general
lvim.log.level = "warn"
lvim.format_on_save.enabled = true
lvim.colorscheme = "catppuccin"
vim.opt.relativenumber = true
vim.opt.guifont = "10"
lvim.transparent_window = true

-- keymappings [view all the defaults by pressing <leader>Lk]
lvim.leader = "space"
lvim.keys.normal_mode["<C-s>"] = ":w<cr>"                           -- save with ctrl+s
lvim.keys.normal_mode["<T-j>"] = ":m .+1<CR>=="                     -- move line down with alt+k
lvim.keys.normal_mode["<T-k>"] = ":m .-2<CR>=="                     -- move line up with alt+j
lvim.keys.normal_mode["|"] = ":vsplit<CR>"                          -- split window vertically
lvim.keys.normal_mode["<Leader>bo"] = ':%bd!|e #|bd #|normal`"<CR>' -- clear all buffers
lvim.keys.normal_mode["<Leader>u"] = ":UndotreeToggle<CR>"          -- undo tree
lvim.keys.normal_mode["<C-d>"] = "<C-d>zz"                          -- scroll down
lvim.keys.normal_mode["<C-u>"] = "<C-u>zz"                          -- scroll up


-- built in lunarvim plugin config
lvim.builtin.alpha.active = true
lvim.builtin.alpha.mode = "dashboard"
lvim.builtin.terminal.active = true
lvim.builtin.nvimtree.setup.view.side = "right"
lvim.builtin.nvimtree.setup.renderer.icons.show.git = false
lvim.builtin.treesitter.highlight.enable = true


lvim.builtin.which_key.mappings["t"] = {
  name = "+Trouble",
  r = { "<cmd>Trouble lsp_references<cr>", "References" },
  f = { "<cmd>Trouble lsp_definitions<cr>", "Definitions" },
  d = { "<cmd>Trouble lsp_document_diagnostics<cr>", "Diagnostics" },
  q = { "<cmd>Trouble quickfix<cr>", "QuickFix" },
  l = { "<cmd>Trouble loclist<cr>", "LocationList" },
  w = { "<cmd>Trouble lsp_workspace_diagnostics<cr>", "Diagnostics" },
}

lvim.builtin.which_key.mappings["o"] = {
  name = "+Obsidian",
  b = { "<cmd>ObsidianBacklinks<cr>", "Backlinks" },
  t = { "<cmd>ObsidianToday<cr>", "Today" },
  y = { "<cmd>ObsidianYesterday<cr>", "Yesterday" },
  o = { "<cmd>ObsidianOpen<cr>", "Open" },
  n = { "<cmd>ObsidianNew<cr>", "New" },
  s = { "<cmd>ObsidianSearch<cr>", "Search" },
  q = { "<cmd>ObsidianQuickSwitch<cr>", "Quick Switch" },
  l = { "<cmd>ObsidianLink<cr>", "Link" },
  L = { "<cmd>ObsidianLinkNew<cr>", "Link New" },
  f = { "<cmd>ObsidianFollowLink<cr>", "Follow Link" },
  T = { "<cmd>ObsidianTemplate<cr>", "Template" },
}

local formatters = require "lvim.lsp.null-ls.formatters"
formatters.setup {
  {
    name = "prettierd",
  },
}

local linters = require "lvim.lsp.null-ls.linters"
linters.setup {

  {
    name = 'eslint'
  }
}


local lspconfig = require "lspconfig"

lspconfig.tailwindcss.setup({
  settings = {
    tailwindCSS = {
      experimental = {
        classRegex = {
          { "cva\\(([^)]*)\\)",
            "[\"'`]([^\"'`]*).*?[\"'`]" },
        },
      },
    },
  },
})
