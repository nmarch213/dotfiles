return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        vtsls = {
          settings = {
            typescript = {
              tsserver = {
                nodePath = vim.fn.exepath("node"),
                maxTsServerMemory = 8192,
              },
            },
          },
        },
      },
    },
  },
}
