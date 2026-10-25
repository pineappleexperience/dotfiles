-- Per-project settings stored outside the project, shared by all checkouts of the same git remote.
local M = {}

local project = require("config.java.project")

local defaults = {
	-- Major version of the JDK for build tasks. null uses the IntelliJ project JDK or $JAVA_HOME.
	jdk = vim.NIL,
	-- Extra arguments for the generic Maven or Gradle tasks, e.g. ["-P", "dev"].
	build_args = {},
	-- Also offer the Maven and Tomcat run configurations of IntelliJ (.run/ and .idea/workspace.xml).
	import_intellij = true,
	-- Own run configurations, see README.md.
	run_configurations = {},
}

local function settings_dir()
	return vim.fn.stdpath("data") .. "/java-projects"
end

local function project_key(root)
	local result = vim.system({ "git", "-C", root, "remote", "get-url", "origin" }, { text = true }):wait()
	local key = result.code == 0 and vim.trim(result.stdout) or root
	key = key:gsub("^%a+://", ""):gsub("^[^@/]+@", ""):gsub("%.git$", "")
	return (key:gsub("[^%w%-%.]", "_"))
end

--- File that holds the settings of the project.
---@param root string
---@return string
function M.file(root)
	return settings_dir() .. "/" .. project_key(root) .. ".json"
end

--- Settings of the project merged with the defaults.
---@param root string
---@return table
function M.load(root)
	local merged = vim.deepcopy(defaults)
	local content = project.read_file(M.file(root))
	if content and content ~= "" then
		local ok, stored = pcall(vim.json.decode, content, { luanil = { object = true, array = true } })
		if ok and type(stored) == "table" then
			merged = vim.tbl_extend("force", merged, stored)
		else
			vim.notify("Invalid JSON in " .. M.file(root), vim.log.levels.ERROR)
		end
	end
	for key, value in pairs(merged) do
		if value == vim.NIL then
			merged[key] = nil
		end
	end
	return merged
end

--- Opens the settings file of the project, creates it with the defaults first.
---@param root string
function M.edit(root)
	local file = M.file(root)
	if vim.uv.fs_stat(file) == nil then
		vim.fn.mkdir(settings_dir(), "p")
		local content = vim.json.encode(defaults, { indent = "  ", sort_keys = true })
		vim.fn.writefile(vim.split(content, "\n"), file)
	end
	vim.cmd.edit(vim.fn.fnameescape(file))
end

--- Environment for build tool and server processes of the project.
---@param root string
---@param jdk? integer major version that overrides the project setting
---@return table<string, string>
function M.env(root, jdk)
	local env = {}
	jdk = jdk or M.load(root).jdk or require("config.java.intellij").project_jdk(root)
	if jdk then
		local home = project.jdk_home(jdk)
		if home then
			env.JAVA_HOME = home
		else
			vim.notify("JDK " .. jdk .. " is not installed, using $JAVA_HOME", vim.log.levels.WARN)
		end
	end
	return env
end

return M
