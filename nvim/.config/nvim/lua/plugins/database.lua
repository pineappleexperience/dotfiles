-- Database client: connections, queries and completion in SQL buffers.
return {
	"kristijanhusak/vim-dadbod-ui",
	dependencies = {
		{ "tpope/vim-dadbod", lazy = true },
		{ "kristijanhusak/vim-dadbod-completion", ft = { "sql", "mysql", "plsql" }, lazy = true },
	},
	cmd = { "DBUI", "DBUIToggle", "DBUIAddConnection", "DBUIFindBuffer" },
	keys = {
		{ "<leader>Du", "<cmd>DBUIToggle<cr>", desc = "[D]atabase [U]I" },
		{ "<leader>Da", "<cmd>DBUIAddConnection<cr>", desc = "[D]atabase: [A]dd connection" },
	},
	init = function()
		vim.g.db_ui_use_nerd_fonts = vim.g.have_nerd_font and 1 or 0
		vim.g.db_ui_save_location = vim.fn.stdpath("data") .. "/db_ui"
	end,
}
