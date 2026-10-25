-- Java and Jakarta EE: jdtls, tests and Spring Boot. See README.md.
return {
	{
		-- jdtls is started from ftplugin/java.lua, or at startup when NeoVim opens without a file in a project
		"mfussenegger/nvim-jdtls",
		lazy = true,
		dependencies = { "mfussenegger/nvim-dap" },
		init = function()
			vim.api.nvim_create_autocmd("VimEnter", {
				group = vim.api.nvim_create_augroup("jdtls-autostart", { clear = true }),
				callback = function()
					local args = vim.fn.argv()
					if #args > 1 or (#args == 1 and vim.fn.isdirectory(args[1]) == 0) then
						return
					end
					local root = require("config.java.project").root(vim.fn.getcwd())
					if root then
						vim.schedule(function()
							require("config.java.jdtls").start_project(root)
						end)
					end
				end,
			})
		end,
	},

	{
		-- provides :NeotestJava, run `:NeotestJava setup` once to download the JUnit console launcher
		"rcasia/neotest-java",
		ft = "java",
	},

	{
		"nvim-neotest/neotest",
		dependencies = {
			"nvim-neotest/nvim-nio",
			"nvim-lua/plenary.nvim",
			"nvim-treesitter/nvim-treesitter",
			"rcasia/neotest-java",
		},
		keys = {
			{
				"<leader>Tn",
				function()
					require("neotest").run.run()
				end,
				desc = "[T]est: run [N]earest",
			},
			{
				"<leader>Td",
				function()
					require("neotest").run.run({ strategy = "dap" })
				end,
				desc = "[T]est: [D]ebug nearest",
			},
			{
				"<leader>Tf",
				function()
					require("neotest").run.run(vim.fn.expand("%"))
				end,
				desc = "[T]est: run [F]ile",
			},
			{
				"<leader>Tl",
				function()
					require("neotest").run.run_last()
				end,
				desc = "[T]est: run [L]ast",
			},
			{
				"<leader>Tx",
				function()
					require("neotest").run.stop()
				end,
				desc = "[T]est: stop",
			},
			{
				"<leader>Ts",
				function()
					require("neotest").summary.toggle()
				end,
				desc = "[T]est: toggle [S]ummary",
			},
			{
				"<leader>To",
				function()
					require("neotest").output.open({ enter = true, auto_close = true })
				end,
				desc = "[T]est: show [O]utput",
			},
			{
				"<leader>TO",
				function()
					require("neotest").output_panel.toggle()
				end,
				desc = "[T]est: toggle [O]utput panel",
			},
			{
				"]t",
				function()
					require("neotest").jump.next({ status = "failed" })
				end,
				desc = "Jump to next failed [t]est",
			},
			{
				"[t",
				function()
					require("neotest").jump.prev({ status = "failed" })
				end,
				desc = "Jump to previous failed [t]est",
			},
		},
		config = function()
			require("neotest").setup({
				adapters = {
					require("neotest-java")({}),
				},
			})
		end,
	},

	{
		-- Spring Boot language server and jdtls extensions, only for projects that depend on Spring Boot
		"JavaHello/spring-boot.nvim",
		ft = { "java", "yaml", "jproperties" },
		dependencies = { "mfussenegger/nvim-jdtls" },
		opts = {
			project_filter = function(root_dir)
				return require("spring_boot.util").has_spring_boot_dependency(root_dir)
			end,
		},
	},
}
