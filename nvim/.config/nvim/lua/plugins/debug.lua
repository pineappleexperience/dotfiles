-- Debugging with nvim-dap. Java debugging comes from jdtls (java-debug-adapter), see config/java/jdtls.lua.
return {
	"mfussenegger/nvim-dap",
	dependencies = {
		-- Creates a beautiful debugger UI
		"rcarriga/nvim-dap-ui",

		-- Required dependency for nvim-dap-ui
		"nvim-neotest/nvim-nio",

		-- will show the values of your variables while your application is running
		"theHamsta/nvim-dap-virtual-text",

		-- Installs the debug adapters for you
		"mason-org/mason.nvim",
		"jay-babu/mason-nvim-dap.nvim",

		-- Add your own debuggers here
		"leoluz/nvim-dap-go",
	},
	keys = {
		-- Basic debugging keymaps, feel free to change to your liking!
		{
			"<F5>",
			function()
				require("dap").continue()
			end,
			desc = "Debug: Start/Continue",
		},
		{
			"<F1>",
			function()
				require("dap").step_into()
			end,
			desc = "Debug: Step Into",
		},
		{
			"<F2>",
			function()
				require("dap").step_over()
			end,
			desc = "Debug: Step Over",
		},
		{
			"<F3>",
			function()
				require("dap").step_out()
			end,
			desc = "Debug: Step Out",
		},
		{
			"<leader>b",
			function()
				require("dap").toggle_breakpoint()
			end,
			desc = "Debug: Toggle Breakpoint",
		},
		{
			"<leader>B",
			function()
				require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
			end,
			desc = "Debug: Set Breakpoint",
		},
		-- Toggle to see last session result. Without this, you can't see session output in case of unhandled exception.
		{
			"<F7>",
			function()
				require("dapui").toggle()
			end,
			desc = "Debug: See last session result.",
		},
		{
			"<leader>dc",
			function()
				require("dap").run_to_cursor()
			end,
			desc = "Debug: Run to [C]ursor",
		},
		{
			"<leader>dl",
			function()
				require("dap").run_last()
			end,
			desc = "Debug: Run [L]ast",
		},
		{
			"<leader>dx",
			function()
				require("dap").terminate()
			end,
			desc = "Debug: Terminate",
		},
		{
			"<leader>dr",
			function()
				require("dap").repl.toggle()
			end,
			desc = "Debug: Toggle [R]EPL",
		},
		{
			"<leader>de",
			function()
				require("dapui").eval()
			end,
			mode = { "n", "x" },
			desc = "Debug: [E]valuate expression",
		},
		{
			"<leader>dp",
			function()
				require("dap").set_breakpoint(nil, nil, vim.fn.input("Log point message: "))
			end,
			desc = "Debug: Log [P]oint",
		},
		{
			"<leader>da",
			function()
				local port = tonumber(vim.fn.input("Debug port: ", "5005"))
				if port then
					require("config.java.run").attach(port)
				end
			end,
			desc = "Debug: [A]ttach to a remote JVM",
		},
	},
	config = function()
		local dap = require("dap")
		local dapui = require("dapui")

		require("mason-nvim-dap").setup({
			-- Makes a best effort to setup the various debuggers with
			-- reasonable debug configurations
			automatic_installation = true,

			-- You can provide additional configuration to the handlers,
			-- see mason-nvim-dap README for more information
			handlers = {},

			-- You'll need to check that you have the required things installed
			-- online, please don't ask me how to install them :)
			ensure_installed = {
				-- Update this to ensure that you have the debuggers for the langs you want
				"codelldb",
				"java-debug-adapter",
				"java-test",
			},
		})

		require("nvim-dap-virtual-text").setup({
			enabled = true,
		})

		-- Dap UI setup
		-- For more information, see |:help nvim-dap-ui|
		dapui.setup({
			-- Set icons to characters that are more likely to work in every terminal.
			--    Feel free to remove or use ones that you like more! :)
			--    Don't feel like these are good choices.
			icons = { expanded = "▾", collapsed = "▸", current_frame = "*" },
			controls = {
				icons = {
					pause = "⏸",
					play = "▶",
					step_into = "⏎",
					step_over = "⏭",
					step_out = "⏮",
					step_back = "b",
					run_last = "▶▶",
					terminate = "⏹",
					disconnect = "⏏",
				},
			},
		})

		-- Change breakpoint icons
		vim.api.nvim_set_hl(0, "DapBreak", { fg = "#e51400" })
		vim.api.nvim_set_hl(0, "DapStop", { fg = "#ffcc00" })
		local breakpoint_icons = vim.g.have_nerd_font
				and {
					Breakpoint = "",
					BreakpointCondition = "",
					BreakpointRejected = "",
					LogPoint = "",
					Stopped = "",
				}
			or {
				Breakpoint = "●",
				BreakpointCondition = "⊜",
				BreakpointRejected = "⊘",
				LogPoint = "◆",
				Stopped = "⭔",
			}
		for type, icon in pairs(breakpoint_icons) do
			local tp = "Dap" .. type
			local hl = (type == "Stopped") and "DapStop" or "DapBreak"
			vim.fn.sign_define(tp, { text = icon, texthl = hl, numhl = hl })
		end

		dap.listeners.after.event_initialized["dapui_config"] = dapui.open
		dap.listeners.before.event_terminated["dapui_config"] = dapui.close
		dap.listeners.before.event_exited["dapui_config"] = dapui.close

		-- Install golang specific config
		require("dap-go").setup({
			delve = {
				-- On Windows delve must be run attached or it crashes.
				-- See https://github.com/leoluz/nvim-dap-go/blob/main/README.md#configuring
				detached = vim.fn.has("win32") == 0,
			},
		})

		dap.configurations.cpp = {
			{
				name = "Launch file (codelldb)",
				type = "codelldb",
				request = "launch",
				program = function()
					return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
				end,
				cwd = "${workspaceFolder}",
				stopOnEntry = false,
			},
		}
		dap.configurations.c = dap.configurations.cpp

		-- jdtls adds the discovered main classes to this list
		dap.configurations.java = {
			{
				type = "java",
				request = "attach",
				name = "Attach to a remote JVM",
				hostName = "127.0.0.1",
				port = function()
					return tonumber(vim.fn.input("Debug port: ", "5005"))
				end,
			},
		}
	end,
}
