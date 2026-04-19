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
			"j-hui/fidget.nvim",
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

			vim.keymap.set({ "n", "v" }, "<leader>aa", "<cmd>CodeCompanionActions<cr>", { desc = "[A]I [A]ctions" })
			vim.keymap.set({ "n", "v" }, "<leader>ac", "<cmd>CodeCompanionChat<cr>", { desc = "[A]I [C]hat" })

			-- CodeCompanion UI notifications
			local progress = require("fidget.progress")
			local handles = {}
			local group = vim.api.nvim_create_augroup("CodeCompanionFidget", {})

			vim.api.nvim_create_autocmd("User", {
				pattern = "CodeCompanionRequestStarted",
				group = group,
				callback = function(e)
					handles[e.data.id] = progress.handle.create({
						title = "CodeCompanion",
						message = "Thinking...",
						lsp_client = { name = e.data.adapter.formatted_name },
					})
				end,
			})

			vim.api.nvim_create_autocmd("User", {
				pattern = "CodeCompanionRequestFinished",
				group = group,
				callback = function(e)
					local h = handles[e.data.id]
					if h then
						h.message = e.data.status == "success" and "Done" or "Failed"
						h:finish()
						handles[e.data.id] = nil
					end
				end,
			})
		end,
	},
}
