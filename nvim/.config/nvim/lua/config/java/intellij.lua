-- Reads IntelliJ IDEA run configurations (Maven and local Tomcat) of a project.
local M = {}

local project = require("config.java.project")

local entities = { quot = '"', amp = "&", lt = "<", gt = ">", apos = "'" }

local function unescape(value)
	return (
		value
			:gsub("&#(%d+);", function(code)
				return string.char(tonumber(code))
			end)
			:gsub("&(%a+);", entities)
	)
end

local function attr(tag, name)
	local value = tag:match("%f[%w_%-]" .. vim.pesc(name) .. '="([^"]*)"')
	return value and unescape(value) or nil
end

local function option(block, name)
	return attr(block:match('<option name="' .. vim.pesc(name) .. '" value="[^"]*"') or "", "value")
end

-- the content between `<option name="NAME">` and the closing tag of its list, set or map
local function option_block(block, name)
	if block:find('<option name="' .. name .. '">%s*<%a+%s*/>') then
		return ""
	end
	return block:match('<option name="' .. name .. '">(.-)</%a+>%s*</option>')
end

local function list_values(block, name)
	local values = {}
	for tag in (option_block(block, name) or ""):gmatch("<option [^>]*>") do
		local value = attr(tag, "value")
		if value then
			table.insert(values, value)
		end
	end
	return values
end

local function map_entries(block, name)
	local entries = {}
	for tag in (option_block(block, name) or ""):gmatch("<entry [^>]*>") do
		local key = attr(tag, "key")
		if key then
			table.insert(entries, { key = key, value = attr(tag, "value") or "" })
		end
	end
	return entries
end

local function expand_macros(value, root)
	return (
		value
			:gsub("%$USER_HOME%$", vim.env.HOME)
			:gsub("%$PROJECT_DIR%$", root)
			:gsub("%$MODULE_DIR%$", root)
			:gsub("%$MAVEN_REPOSITORY%$", project.maven_repository())
	)
end

local function jdk_major(name)
	if not name or name == "" or name:match("^#") then
		return nil
	end
	if name:match("1%.8") then
		return 8
	end
	local major = name:match("(%d+)")
	return major and tonumber(major) or nil
end

--- Major version of the project JDK configured in IntelliJ.
---@param root string
---@return integer|nil
function M.project_jdk(root)
	local misc = project.read_file(root .. "/.idea/misc.xml")
	return misc and jdk_major(attr(misc:match('<component name="ProjectRootManager"[^>]*>') or "", "project-jdk-name"))
end

local function config_dirs()
	local dirs = {}
	for _, pattern in ipairs({
		vim.env.HOME .. "/Library/Application Support/JetBrains/IntelliJIdea*",
		vim.env.HOME .. "/.config/JetBrains/IntelliJIdea*",
	}) do
		vim.list_extend(dirs, vim.fn.glob(pattern, false, true))
	end
	table.sort(dirs, function(a, b)
		return a > b
	end)
	return dirs
end

local app_servers

--- Tomcat installations configured in IntelliJ, by name.
---@return table<string, string>
function M.application_servers()
	if app_servers then
		return app_servers
	end
	app_servers = {}
	for _, dir in ipairs(config_dirs()) do
		local content = project.read_file(dir .. "/options/javaeeAppServers.xml")
		if content then
			for name, block in content:gmatch('<ServerDK NAME="([^"]*)">(.-)</ServerDK>') do
				local home = option(block, "CATALINA_HOME")
				if home and not app_servers[unescape(name)] then
					app_servers[unescape(name)] = expand_macros(home, "")
				end
			end
		end
	end
	return app_servers
end

local function module_dir(root, artifact)
	local module = artifact:match("^([^:]+)")
	for _, pattern in ipairs({ "/%s/pom.xml", "/*/%s/pom.xml", "/*/*/%s/pom.xml" }) do
		local pom = vim.fn.glob(root .. pattern:format(module), false, true)[1]
		if pom then
			return vim.fs.dirname(pom):sub(#root + 2)
		end
	end
	return nil
end

local function maven_configuration(block, name, root)
	local args = list_values(block, "goals")
	local profiles = {}
	for _, entry in ipairs(map_entries(block, "profilesMap")) do
		table.insert(profiles, (entry.value == "false" and "!" or "") .. entry.key)
	end
	if #profiles > 0 then
		vim.list_extend(args, { "-P", table.concat(profiles, ",") })
	end
	for _, entry in ipairs(map_entries(block, "mavenProperties")) do
		table.insert(args, "-D" .. entry.key .. "=" .. entry.value)
	end
	if option(block, "skipTests") == "true" then
		table.insert(args, "-DskipTests")
	end
	local cmd_options = option(block, "cmdOptions")
	if cmd_options and cmd_options ~= "" then
		vim.list_extend(args, vim.split(cmd_options, "%s+", { trimempty = true }))
	end
	local env = {}
	for _, entry in ipairs(map_entries(block, "environmentProperties")) do
		env[entry.key] = expand_macros(entry.value, root)
	end
	local vm_options = option(block, "vmOptions")
	if vm_options and vm_options ~= "" then
		env.MAVEN_OPTS = vm_options
	end
	local working_dir = option(block, "workingDirPath")
	return {
		name = name,
		type = "maven",
		args = vim.tbl_map(function(arg)
			return expand_macros(arg, root)
		end, args),
		cwd = working_dir and expand_macros(working_dir, root) or root,
		env = env,
		jdk = jdk_major(option(block, "jreName")) or M.project_jdk(root),
	}
end

local function tomcat_configuration(tag, block, name, root)
	local runner = block:match('<ConfigurationWrapper[^>]*RunnerId="Debug"[^>]*>(.-)</ConfigurationWrapper>')
		or block:match('<ConfigurationWrapper[^>]*RunnerId="Run"[^>]*>(.-)</ConfigurationWrapper>')
		or ""
	local env = {}
	for env_block in runner:gmatch("<EnvironmentVariables>(.-)</EnvironmentVariables>") do
		local key
		for option_name, value in env_block:gmatch('<option name="([^"]*)" value="([^"]*)"') do
			if option_name == "NAME" then
				key = unescape(value)
			elseif option_name == "VALUE" and key then
				env[key] = expand_macros(unescape(value), root)
				key = nil
			end
		end
	end
	local vm_parameters = option(runner, "VM_PARAMETERS") or ""

	local configuration = {
		name = name,
		type = "tomcat",
		tomcat_home = M.application_servers()[attr(tag, "APPLICATION_SERVER_NAME") or ""],
		context_path = "/",
		http_port = tonumber(option(block, "HTTP_PORT") or "") or 8080,
		debug_port = tonumber(option(block, "DEBUG_PORT") or "") or 5005,
		jvm_args = vim.split(expand_macros(vm_parameters, root), "%s+", { trimempty = true }),
		env = env,
		jdk = attr(tag, "ALTERNATIVE_JRE_ENABLED") == "true" and jdk_major(attr(tag, "ALTERNATIVE_JRE_PATH"))
			or M.project_jdk(root),
	}
	local deployment = block:match("<deployment>(.-)</deployment>") or ""
	local artifact = deployment:match('<artifact name="([^"]*)"')
	local file = deployment:match('<file path="([^"]*)"')
	if artifact then
		configuration.war_module = module_dir(root, unescape(artifact))
	elseif file then
		configuration.war = expand_macros(unescape(file), root)
	end
	configuration.context_path = option(deployment, "CONTEXT_PATH") or "/"
	return configuration
end

local function parse(content, root, result)
	for tag, block in content:gmatch("(<configuration [^>]*[^/]>)(.-)</configuration>") do
		local name = attr(tag, "name")
		local type = attr(tag, "type") or ""
		if name and attr(tag, "default") ~= "true" and attr(tag, "temporary") ~= "true" then
			if type == "MavenRunConfiguration" then
				table.insert(result, maven_configuration(block, name, root))
			elseif type:find("TomcatRunConfigurationFactory", 1, true) and attr(tag, "factoryName") == "Local" then
				table.insert(result, tomcat_configuration(tag, block, name, root))
			end
		end
	end
end

--- Maven and local Tomcat run configurations of the project, from `.run/` and `.idea/workspace.xml`.
---@param root string
---@return table[]
function M.run_configurations(root)
	local result = {}
	for _, file in ipairs(vim.fn.glob(root .. "/.run/*.run.xml", false, true)) do
		parse(project.read_file(file) or "", root, result)
	end
	local workspace = project.read_file(root .. "/.idea/workspace.xml")
	if workspace then
		parse(workspace, root, result)
	end
	for _, configuration in ipairs(result) do
		configuration.source = "IntelliJ"
	end
	return result
end

return M
