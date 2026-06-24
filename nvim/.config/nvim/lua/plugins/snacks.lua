-- lazy.nvim
return {
  "folke/snacks.nvim",
  ---@type snacks.Config
  opts = {
    picker = {
      sources = {
        explorer = {
          layout = { layout = { position = "right" } },
          -- your explorer picker configuration comes here
          -- or leave it empty to use the default settings
        },
      },
    },
  },
}
