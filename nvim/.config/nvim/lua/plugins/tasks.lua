-- Build tasks, run configurations (Maven, Tomcat) and other tasks (npm, make, ...), managed by overseer.nvim.
local function run(name)
	return function()
		require("config.java.tasks").run(name)
	end
end

local function server(subcommand)
	return "<cmd>JavaServer " .. subcommand .. "<cr>"
end

local function rerun_last()
	local overseer = require("overseer")
	local latest
	for _, task in ipairs(overseer.list_tasks({})) do
		if
			task.time_start
			and (
				not latest
				or task.time_start > latest.time_start
				or (task.time_start == latest.time_start and task.id > latest.id)
			)
		then
			latest = task
		end
	end
	if latest then
		overseer.run_action(latest, "restart")
	else
		vim.notify("No task has run yet", vim.log.levels.WARN)
	end
end

local function stop_task()
	local overseer = require("overseer")
	local running = overseer.list_tasks({ status = { overseer.STATUS.RUNNING } })
	if #running == 1 then
		running[1]:stop()
	elseif #running > 1 then
		vim.ui.select(running, {
			prompt = "Stop",
			format_item = function(task)
				return task.name
			end,
		}, function(task)
			if task then
				task:stop()
			end
		end)
	else
		vim.notify("No task is running", vim.log.levels.INFO)
	end
end

return {
	"stevearc/overseer.nvim",
	cmd = {
		"OverseerRun",
		"OverseerToggle",
		"OverseerOpen",
		"OverseerShell",
		"OverseerTaskAction",
		"JavaServer",
		"JavaSettings",
	},
	keys = {
		{ "<leader>rr", "<cmd>OverseerRun<cr>", desc = "[R]un configuration or task" },
		{ "<leader>rl", rerun_last, desc = "Rerun [L]ast task" },
		{ "<leader>rx", stop_task, desc = "Stop a running task" },
		{ "<leader>ro", "<cmd>OverseerToggle!<cr>", desc = "Toggle task [O]verview" },
		{ "<leader>ra", "<cmd>OverseerTaskAction<cr>", desc = "Task [A]ction" },
		{ "<leader>rm", run("build module"), desc = "Build current [M]odule" },
		{ "<leader>rp", run("build project"), desc = "Build [P]roject" },
		{ "<leader>rc", run("compile module"), desc = "[C]ompile current module" },
		{ "<leader>rt", run("test module"), desc = "[T]est current module" },
		{ "<leader>rT", run("test current class"), desc = "[T]est current class" },
		{ "<leader>rs", "<cmd>JavaSettings<cr>", desc = "Project [S]ettings" },

		{ "<leader>wd", server("debug"), desc = "Start server with [D]ebugger" },
		{ "<leader>ws", server("start"), desc = "[S]tart server" },
		{ "<leader>wx", server("stop"), desc = "Stop server" },
		{ "<leader>wb", server("build"), desc = "[B]uild WAR" },
		{ "<leader>wr", server("rebuild"), desc = "[R]ebuild WAR and restart with debugger" },
		{ "<leader>wl", server("log"), desc = "Server [L]og" },
		{ "<leader>wa", server("attach"), desc = "[A]ttach debugger" },
		{ "<leader>wo", server("open"), desc = "[O]pen in browser" },
		{ "<leader>ww", server("select"), desc = "Select server" },
	},
	config = function()
		require("overseer").setup({
			task_list = { direction = "bottom" },
		})
		require("config.java.tasks").register()
		require("config.java.run").register()
		require("config.java.run").create_command()
		vim.api.nvim_create_user_command("JavaSettings", function()
			local root = require("config.java.project").root(0)
			if root then
				require("config.java.settings").edit(root)
			else
				vim.notify("Not inside a Maven or Gradle project", vim.log.levels.WARN)
			end
		end, { desc = "Edit the settings of the current Java project" })
	end,
}
