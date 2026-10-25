-- Here is a more advanced example where we pass configuration
-- options to `gitsigns.nvim`.
--
-- See `:help gitsigns` to understand what the configuration keys do
return { -- Adds git related signs to the gutter, as well as utilities for managing changes
	{
		"lewis6991/gitsigns.nvim",
		opts = {
			signs = {
				add = { text = "+" },
				change = { text = "~" },
				delete = { text = "_" },
				topdelete = { text = "‾" },
				changedelete = { text = "~" },
			},
			on_attach = function(bufnr)
				local gitsigns = require("gitsigns")

				local function map(mode, l, r, opts)
					opts = opts or {}
					opts.buffer = bufnr
					vim.keymap.set(mode, l, r, opts)
				end

				-- Navigation
				map("n", "]c", function()
					if vim.wo.diff then
						vim.cmd.normal({ "]c", bang = true })
					else
						gitsigns.nav_hunk("next")
					end
				end, { desc = "Jump to next git [c]hange" })

				map("n", "[c", function()
					if vim.wo.diff then
						vim.cmd.normal({ "[c", bang = true })
					else
						gitsigns.nav_hunk("prev")
					end
				end, { desc = "Jump to previous git [c]hange" })

				-- Actions
				-- visual mode
				map("v", "<leader>hs", function()
					gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
				end, { desc = "git [s]tage hunk" })
				map("v", "<leader>hr", function()
					gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
				end, { desc = "git [r]eset hunk" })
				-- normal mode
				map("n", "<leader>hs", gitsigns.stage_hunk, { desc = "git [s]tage hunk" })
				map("n", "<leader>hr", gitsigns.reset_hunk, { desc = "git [r]eset hunk" })
				map("n", "<leader>hS", gitsigns.stage_buffer, { desc = "git [S]tage buffer" })
				map("n", "<leader>hu", gitsigns.stage_hunk, { desc = "git [u]ndo stage hunk" })
				map("n", "<leader>hR", gitsigns.reset_buffer, { desc = "git [R]eset buffer" })
				map("n", "<leader>hp", gitsigns.preview_hunk, { desc = "git [p]review hunk" })
				map("n", "<leader>hb", gitsigns.blame_line, { desc = "git [b]lame line" })
				map("n", "<leader>hd", gitsigns.diffthis, { desc = "git [d]iff against index" })
				map("n", "<leader>hD", function()
					gitsigns.diffthis("@")
				end, { desc = "git [D]iff against last commit" })
				-- Toggles
				map("n", "<leader>tb", gitsigns.toggle_current_line_blame, { desc = "[T]oggle git show [b]lame line" })
				map("n", "<leader>tD", gitsigns.preview_hunk_inline, { desc = "[T]oggle git show [D]eleted" })
			end,
		},
	},

	{
		"tpope/vim-fugitive",
		config = function()
			-- Set a vim motion to <Space> + g + b to view the most recent contributers to the file
			vim.keymap.set("n", "<leader>gb", ":Git blame<cr>", { desc = "[G]it [B]lame" })
			-- Set a vim motion to <Space> + g + <Shift>A to all files changed to the staging area
			vim.keymap.set("n", "<leader>gA", ":Git add .<cr>", { desc = "[G]it Add [A]ll" })
			-- Set a vim motion to <Space> + g + a to add the current file and changes to the staging area
			vim.keymap.set("n", "<leader>ga", "<cmd>Git add %<cr>", { desc = "[G]it [A]dd" })
			-- Set a vim motion to <Space> + g + c to commit the current chages
			vim.keymap.set("n", "<leader>gc", ":Git commit", { desc = "[G]it [C]ommit" })
			-- Set a vim motion to <Space> + g + p to push the commited changes to the remote repository
			vim.keymap.set("n", "<leader>gp", "<cmd>Git push<cr>", { desc = "[G]it [P]ush" })
			vim.keymap.set("n", "<leader>gs", "<cmd>Git<cr>", { desc = "[G]it [S]tatus" })
		end,
	},

	{ -- lazygit in a floating window, files opened from lazygit open in this NeoVim
		"kdheepak/lazygit.nvim",
		cmd = { "LazyGit", "LazyGitCurrentFile", "LazyGitLog", "LazyGitFilterCurrentFile" },
		dependencies = { "nvim-lua/plenary.nvim" },
		keys = {
			{ "<leader>gl", "<cmd>LazyGit<cr>", desc = "[G]it: [L]azygit" },
			{ "<leader>gL", "<cmd>LazyGitFilterCurrentFile<cr>", desc = "[G]it: [L]azygit commits of the file" },
		},
	},

	{ -- Side-by-side diffs of local changes, branches, merge requests and file history
		"dlyongemallo/diffview.nvim",
		cmd = { "DiffviewOpen", "DiffviewFileHistory", "Review", "ReviewMR" },
		keys = {
			{ "<leader>gd", "<cmd>DiffviewOpen<cr>", desc = "[G]it [D]iff of local changes" },
			{ "<leader>gr", "<cmd>Review<cr>", desc = "[G]it [R]eview branch against its target" },
			{ "<leader>gm", "<cmd>ReviewMR<cr>", desc = "[G]it review [M]erge request" },
			{
				"<leader>gM",
				function()
					require("config.git_review").open_in_browser()
				end,
				desc = "[G]it open [M]erge request in browser",
			},
			{ "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", desc = "[G]it file [H]istory" },
			{ "<leader>gH", "<cmd>DiffviewFileHistory<cr>", desc = "[G]it branch [H]istory" },
			{ "<leader>gh", ":DiffviewFileHistory<cr>", mode = "x", desc = "[G]it [H]istory of selection" },
			{ "<leader>gq", "<cmd>DiffviewClose<cr>", desc = "[G]it close diff view" },
		},
		opts = {
			enhanced_diff_hl = true,
			view = {
				merge_tool = { layout = "diff3_mixed" },
			},
		},
		config = function(_, opts)
			require("diffview").setup(opts)
			vim.api.nvim_create_user_command("Review", function(args)
				require("config.git_review").review(args.args)
			end, { nargs = "?", desc = "Review the current branch against a branch, default: the MR target" })
			vim.api.nvim_create_user_command("ReviewMR", function()
				require("config.git_review").pick_request()
			end, { desc = "Check out an open merge request and review it" })
		end,
	},
}
