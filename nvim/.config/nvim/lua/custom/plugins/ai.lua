return {
	-- 1) GitHub Copilot (the provider)
	{
		"zbirenbaum/copilot.lua",
		cmd = "Copilot",
		event = "InsertEnter",
		opts = {
			-- keep Copilot suggestions under *your* control
			suggestion = {
				enabled = true,
				auto_trigger = false, -- important: don't pop suggestions unless you ask
			},
			panel = { enabled = true },
		},
		config = function()
			require("copilot").setup({})
		end,
	},

	-- 2) CodeCompanion (chat/commands UI)
	{
		"olimorris/codecompanion.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-telescope/telescope.nvim",
		},
		opts = {
			chat = {
				adapters = "copilot",
			},
			inline = {
				adapters = "copilot",
			},
		},
		config = function(_, opts)
			require("codecompanion").setup(opts)

			-- Optional keymaps (manual triggers)
			vim.keymap.set({ "n", "v" }, "<leader>aa", "<cmd>CodeCompanionActions<cr>", { desc = "[A]I [A]ctions" })
			vim.keymap.set({ "n", "v" }, "<leader>ac", "<cmd>CodeCompanionChat<cr>", { desc = "[A]I [C]hat" })
		end,
	},
}
