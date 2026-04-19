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
				model = "gpt-5.2",
			},
			inline = {
				adapters = "copilot",
				model = "gpt-5.2",
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

			-- Telescope picker for CodeCompanion models
			local function codecompanion_model_picker()
				local pickers = require("telescope.pickers")
				local finders = require("telescope.finders")
				local actions = require("telescope.actions")
				local action_state = require("telescope.actions.state")
				local conf = require("telescope.config").values

				local function get_available_models()
					local ok, cc = pcall(require, "codecompanion")
					if ok and cc and cc.models then
						local models = cc.models.list and cc.models.list() or {}
						if #models > 0 then
							return models
						end
					end
					return { "gpt-4", "gpt-4o", "gpt-5.2", "gpt-3.5-turbo" }
				end

				local function set_model(kind, model)
					if opts[kind] then
						opts[kind].model = model
						vim.notify(
							kind:sub(1, 1):upper() .. kind:sub(2) .. " model set to " .. model,
							vim.log.levels.INFO,
							{ title = "CodeCompanion" }
						)
					end
				end

				local models = get_available_models()
				local entries = {}
				local chat_model = opts.chat and opts.chat.model or "N/A"
				local inline_model = opts.inline and opts.inline.model or "N/A"

				table.insert(entries, { display = "Current chat model: " .. chat_model, value = nil })
				table.insert(entries, { display = "Current inline model: " .. inline_model, value = nil })
				table.insert(entries, { display = "--- Select to set chat or inline model ---", value = nil })
				for _, m in ipairs(models) do
					table.insert(entries, { display = "Set chat model: " .. m, value = { kind = "chat", model = m } })
					table.insert(
						entries,
						{ display = "Set inline model: " .. m, value = { kind = "inline", model = m } }
					)
				end

				pickers
					.new({}, {
						prompt_title = "CodeCompanion Models",
						finder = finders.new_table({
							results = entries,
							entry_maker = function(entry)
								return {
									value = entry.value,
									display = entry.display,
									ordinal = entry.display,
								}
							end,
						}),
						sorter = conf.generic_sorter({}),
						attach_mappings = function(_, map)
							actions.select_default:replace(function(prompt_bufnr)
								local selection = action_state.get_selected_entry()
								actions.close(prompt_bufnr)
								if selection and selection.value then
									set_model(selection.value.kind, selection.value.model)
								end
							end)
							return true
						end,
					})
					:find()
			end

			vim.api.nvim_create_user_command(
				"CodeCompanionModelPicker",
				codecompanion_model_picker,
				{ desc = "Telescope picker for CodeCompanion models" }
			)
			vim.keymap.set("n", "<leader>am", ":CodeCompanionModelPicker<cr>", { desc = "[A]I [M]odel picker" })
		end,
	},
}
