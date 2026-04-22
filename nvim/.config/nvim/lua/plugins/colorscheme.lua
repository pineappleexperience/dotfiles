-- If you want to see what colorschemes are already installed, you can use `:Telescope colorscheme`.
return {
	{ "jacoborus/tender.vim" },
	{ "catppuccin/nvim" },
	{
		"rebelot/kanagawa.nvim",
		priority = 1000,
		config = function()
			vim.cmd.colorscheme("kanagawa")
		end,
	},
	{ "bluz71/vim-moonfly-colors" },

	{
		"folke/tokyonight.nvim",
		priority = 1000,
		config = function()
			---@diagnostic disable-next-line: missing-fields
			require("tokyonight").setup({
				styles = {
					comments = { italic = false }, -- Disable italics in comments
				},
			})

			-- vim.cmd.colorscheme("tokyonight-night")
		end,
	},
}
