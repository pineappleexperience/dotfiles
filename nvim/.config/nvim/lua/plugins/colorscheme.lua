-- Rosé Pine: Moon when the terminal is dark, Dawn when it is light. NeoVim sets 'background' from the
-- terminal's colours and reloads the colorscheme when it changes.
return {
	"rose-pine/neovim",
	name = "rose-pine",
	lazy = false,
	priority = 1000,
	config = function()
		require("rose-pine").setup({
			variant = "auto",
			dark_variant = "moon",
			styles = {
				italic = false,
			},
		})
		vim.cmd.colorscheme("rose-pine")
	end,
}
