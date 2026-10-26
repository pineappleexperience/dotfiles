-- Sessions per directory and git branch: saved on exit, restored when NeoVim starts without arguments
return {
	"folke/persistence.nvim",
	lazy = false,
	opts = {},
	init = function()
		vim.api.nvim_create_autocmd("VimEnter", {
			group = vim.api.nvim_create_augroup("restore-session", { clear = true }),
			nested = true,
			callback = function()
				if vim.fn.argc() == 0 and not vim.g.started_with_stdin then
					require("persistence").load()
				end
			end,
		})
		vim.api.nvim_create_autocmd("StdinReadPre", {
			group = vim.api.nvim_create_augroup("restore-session-stdin", { clear = true }),
			callback = function()
				vim.g.started_with_stdin = true
			end,
		})
	end,
	keys = {
		{
			"<leader>sS",
			function()
				require("persistence").select()
			end,
			desc = "[S]earch [S]essions",
		},
	},
}
