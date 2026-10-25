-- overseer.nvim tasks for Maven and Gradle projects.
local M = {}

local project = require("config.java.project")
local settings = require("config.java.settings")

-- javac errors from Maven ("[ERROR] /path/File.java:[12,5] msg") and Gradle ("/path/File.java:12: error: msg")
M.errorformat = table.concat({
	"[%tRROR] %f:[%l\\,%c] %m",
	"[%tARNING] %f:[%l\\,%c] %m",
	"%f:%l: %trror: %m",
	"%f:%l: %tarning: %m",
}, ",")

local function test_class(bufnr)
	local name = vim.api.nvim_buf_get_name(bufnr)
	if not name:match("%.java$") then
		return nil
	end
	return vim.fn.fnamemodify(name, ":t:r")
end

-- Arguments for each task, per build tool. `module` is the module path relative to the root or nil.
local definitions = {
	{
		name = "build project",
		maven = function()
			return { "install", "-DskipTests" }
		end,
		gradle = function()
			return { "build", "-x", "test" }
		end,
	},
	{
		name = "build module",
		maven = function(module)
			return module and { "install", "-DskipTests", "-pl", module, "-am" } or { "install", "-DskipTests" }
		end,
		gradle = function(module)
			return { module and ":" .. module:gsub("/", ":") .. ":build" or "build", "-x", "test" }
		end,
	},
	{
		name = "compile module",
		maven = function(module)
			return module and { "compile", "-pl", module, "-am" } or { "compile" }
		end,
		gradle = function(module)
			return { module and ":" .. module:gsub("/", ":") .. ":classes" or "classes" }
		end,
	},
	{
		name = "test module",
		maven = function(module)
			return module and { "test", "-pl", module } or { "test" }
		end,
		gradle = function(module)
			return { module and ":" .. module:gsub("/", ":") .. ":test" or "test" }
		end,
	},
	{
		name = "test current class",
		maven = function(module, bufnr)
			local class = test_class(bufnr)
			local args = { "test", "-Dsurefire.failIfNoSpecifiedTests=false", "-Dtest=" .. (class or "*") }
			if module then
				vim.list_extend(args, { "-pl", module })
			end
			return args
		end,
		gradle = function(module, bufnr)
			local class = test_class(bufnr)
			return { module and ":" .. module:gsub("/", ":") .. ":test" or "test", "--tests", "*." .. (class or "*") }
		end,
	},
	{
		name = "format module (spotless)",
		maven = function(module)
			return module and { "spotless:apply", "-pl", module } or { "spotless:apply" }
		end,
		gradle = function(module)
			return { module and ":" .. module:gsub("/", ":") .. ":spotlessApply" or "spotlessApply" }
		end,
	},
	{
		name = "clean project",
		maven = function()
			return { "clean" }
		end,
		gradle = function()
			return { "clean" }
		end,
	},
}

local function common_args(tool)
	if tool == "maven" then
		return { "-B", "-ntp" }
	end
	return { "--console=plain" }
end

--- Task definition for a build tool invocation in the project of the buffer.
---@param bufnr integer
---@param name string task name shown by overseer
---@param args string[] arguments for the build tool
---@return table|nil
function M.task(bufnr, name, args)
	local root = project.root(bufnr)
	local tool = root and project.build_tool(root)
	if not tool then
		return nil
	end
	local cmd = { project.build_command(root) }
	vim.list_extend(cmd, common_args(tool))
	vim.list_extend(cmd, settings.load(root).build_args)
	vim.list_extend(cmd, args)
	return {
		name = name,
		cmd = cmd,
		cwd = root,
		env = settings.env(root),
		components = {
			{ "on_output_quickfix", errorformat = M.errorformat, items_only = true, open_on_exit = "failure" },
			"default",
		},
	}
end

local function templates(bufnr)
	local root = project.root(bufnr)
	local tool = root and project.build_tool(root)
	if not tool then
		return {}
	end
	local module_dir = project.module_dir(bufnr) or root
	local module = project.relative_module(root, module_dir)
	local result = {}
	for _, definition in ipairs(definitions) do
		local title = string.format("%s: %s", tool == "maven" and "Maven" or "Gradle", definition.name)
		table.insert(result, {
			name = title,
			builder = function()
				return M.task(bufnr, title .. (module and " (" .. module .. ")" or ""), definition[tool](module, bufnr))
			end,
		})
	end
	table.insert(result, {
		name = (tool == "maven" and "Maven" or "Gradle") .. ": custom goals",
		params = {
			goals = { type = "string", desc = "Goals/tasks and arguments, separated by spaces" },
		},
		builder = function(params)
			return M.task(bufnr, params.goals, vim.split(params.goals, "%s+", { trimempty = true }))
		end,
	})
	return result
end

--- Registers the template provider with overseer.
function M.register()
	require("overseer").register_template({
		name = "Java build",
		generator = function(_)
			local bufnr = vim.api.nvim_get_current_buf()
			if not project.root(bufnr) or not project.build_tool(project.root(bufnr)) then
				return "Not a Maven or Gradle project"
			end
			return templates(bufnr)
		end,
	})
end

--- Runs a task of the provider by its name without the build tool prefix, e.g. "build module".
---@param name string
function M.run(name)
	local bufnr = vim.api.nvim_get_current_buf()
	local root = project.root(bufnr)
	local tool = root and project.build_tool(root)
	if not tool then
		vim.notify("Not a Maven or Gradle project", vim.log.levels.WARN)
		return
	end
	for _, template in ipairs(templates(bufnr)) do
		if template.name == string.format("%s: %s", tool == "maven" and "Maven" or "Gradle", name) then
			local task = require("overseer").new_task(template.builder({}))
			task:start()
			return
		end
	end
end

return M
