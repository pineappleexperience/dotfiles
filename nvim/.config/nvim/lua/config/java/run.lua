-- Run configurations like in IntelliJ: Maven goals and local Tomcat servers, run as overseer tasks.
local M = {}

local project = require("config.java.project")
local settings = require("config.java.settings")
local tasks = require("config.java.tasks")

local function current_root()
	local root = project.root(0)
	if not root then
		vim.notify("Not inside a Maven or Gradle project", vim.log.levels.WARN)
	end
	return root
end

local function expand(value, root)
	return (vim.fn.expand(value):gsub("%${root}", root))
end

--- Run configurations of the project: own ones from the settings first, then the ones from IntelliJ.
---@param root string
---@return table[]
function M.configurations(root)
	local config = settings.load(root)
	local result, names = {}, {}
	for _, configuration in ipairs(config.run_configurations or {}) do
		configuration = vim.deepcopy(configuration)
		configuration.source = "settings"
		table.insert(result, configuration)
		names[configuration.name] = true
	end
	if config.import_intellij ~= false then
		for _, configuration in ipairs(require("config.java.intellij").run_configurations(root)) do
			if not names[configuration.name] then
				table.insert(result, configuration)
			end
		end
	end
	return result
end

local function maven_task(root, configuration)
	local cmd = { project.build_command(root), "-B", "-ntp" }
	vim.list_extend(
		cmd,
		vim.tbl_map(function(arg)
			return expand(arg, root)
		end, configuration.args or {})
	)
	local env = vim.tbl_extend("force", settings.env(root, configuration.jdk), configuration.env or {})
	return {
		name = configuration.name,
		cmd = cmd,
		cwd = configuration.cwd and expand(configuration.cwd, root) or root,
		env = env,
		components = {
			{ "on_output_quickfix", errorformat = tasks.errorformat, items_only = true, open_on_exit = "failure" },
			"default",
		},
		metadata = { java_root = root },
	}
end

local function exploded_war(root, configuration)
	if configuration.war then
		local war = expand(configuration.war, root)
		return vim.uv.fs_stat(war) and war or nil
	end
	local module = configuration.war_module and vim.fs.joinpath(root, configuration.war_module) or root
	local newest, newest_mtime
	for _, web_inf in ipairs(vim.fn.glob(module .. "/target/*/WEB-INF", false, true)) do
		local stat = vim.uv.fs_stat(web_inf)
		if stat and (not newest_mtime or stat.mtime.sec > newest_mtime) then
			newest, newest_mtime = vim.fs.dirname(web_inf), stat.mtime.sec
		end
	end
	return newest
end

local function context_file_name(context_path)
	local name = (context_path or "/"):gsub("^/+", ""):gsub("/+$", ""):gsub("/", "#")
	return name == "" and "ROOT" or name
end

-- A CATALINA_BASE per project root and run configuration, so one Tomcat installation serves all of them.
local function prepare_base(root, configuration, docbase)
	local key = vim.fn.sha256(root .. "\0" .. configuration.name):sub(1, 8)
	local base = vim.fn.stdpath("cache") .. "/java-server/" .. vim.fs.basename(root) .. "-" .. key
	for _, dir in ipairs({ "conf/Catalina/localhost", "logs", "temp", "work", "webapps" }) do
		vim.fn.mkdir(base .. "/" .. dir, "p")
	end
	local tomcat_home = expand(configuration.tomcat_home, root)
	for name, type in vim.fs.dir(tomcat_home .. "/conf") do
		if type == "file" and name ~= "server.xml" then
			vim.uv.fs_copyfile(tomcat_home .. "/conf/" .. name, base .. "/conf/" .. name)
		end
	end

	local server_xml = project
		.read_file(tomcat_home .. "/conf/server.xml")
		:gsub('(<Server%s+port=")%d+(")', "%1-1%2")
		:gsub('(<Connector%s+port=")%d+("%s+protocol="HTTP/1%.1")', "%1" .. (configuration.http_port or 8080) .. "%2")
	vim.fn.writefile(vim.split(server_xml, "\n", { plain = true }), base .. "/conf/server.xml")

	for _, old in ipairs(vim.fn.glob(base .. "/conf/Catalina/localhost/*.xml", false, true)) do
		vim.fn.delete(old)
	end
	vim.fn.writefile({
		'<?xml version="1.0" encoding="UTF-8"?>',
		string.format('<Context docBase="%s" />', docbase),
	}, base .. "/conf/Catalina/localhost/" .. context_file_name(configuration.context_path) .. ".xml")
	return base
end

local function tomcat_task(root, configuration, debug)
	local tomcat_home = configuration.tomcat_home and expand(configuration.tomcat_home, root)
	if not tomcat_home or not vim.uv.fs_stat(tomcat_home .. "/bin/catalina.sh") then
		vim.notify(
			string.format("Tomcat of %q not found: %s", configuration.name, tostring(tomcat_home)),
			vim.log.levels.ERROR
		)
		return nil
	end
	local docbase = exploded_war(root, configuration)
	if not docbase then
		vim.notify(
			string.format("No WAR for %q, build it first (:JavaServer build)", configuration.name),
			vim.log.levels.ERROR
		)
		return nil
	end

	local base = prepare_base(root, configuration, docbase)
	local debug_port = configuration.debug_port or 5005
	local jvm_args = vim.tbl_map(function(arg)
		return expand(arg, root)
	end, configuration.jvm_args or {})
	local env = vim.tbl_extend("force", settings.env(root, configuration.jdk), {
		CATALINA_HOME = tomcat_home,
		CATALINA_BASE = base,
		CATALINA_OPTS = table.concat(jvm_args, " "),
		JPDA_ADDRESS = "localhost:" .. debug_port,
		JPDA_SUSPEND = "n",
	})
	for key, value in pairs(configuration.env or {}) do
		env[key] = expand(value, root)
	end

	local components = { "default", { "unique", replace = true } }
	local cmd = { tomcat_home .. "/bin/catalina.sh", "run" }
	if debug then
		table.insert(components, { "java.attach_debugger", port = debug_port })
		table.insert(cmd, 2, "jpda")
	end
	return {
		name = configuration.name,
		cmd = cmd,
		cwd = base,
		env = env,
		components = components,
		metadata = {
			java_root = root,
			server = true,
			url = string.format(
				"http://localhost:%d%s",
				configuration.http_port or 8080,
				configuration.context_path or "/"
			),
		},
	}
end

--- Task definition for a run configuration.
---@param root string
---@param configuration table
---@param debug? boolean start servers with the debugger attached
---@return table|nil
function M.task(root, configuration, debug)
	if configuration.type == "tomcat" then
		return tomcat_task(root, configuration, debug)
	end
	return maven_task(root, configuration)
end

--- Starts a run configuration.
---@param root string
---@param configuration table
---@param debug? boolean
function M.run(root, configuration, debug)
	local definition = M.task(root, configuration, debug)
	if definition then
		require("overseer").new_task(definition):start()
		if configuration.type == "tomcat" then
			vim.notify(string.format("%s starting on %s", configuration.name, definition.metadata.url))
		end
	end
end

local function wait_for_port(port, timeout_ms, callback)
	local deadline = vim.uv.now() + timeout_ms
	local function attempt()
		local tcp = vim.uv.new_tcp()
		tcp:connect("127.0.0.1", port, function(err)
			tcp:close()
			if not err then
				vim.schedule(callback)
			elseif vim.uv.now() < deadline then
				vim.defer_fn(attempt, 500)
			else
				vim.schedule(function()
					vim.notify("Debug port " .. port .. " did not open", vim.log.levels.ERROR)
				end)
			end
		end)
	end
	attempt()
end

--- Attaches the debugger to a JVM that listens on the given port.
---@param port integer
function M.attach(port)
	local dap = require("dap")
	if not dap.adapters.java then
		vim.notify(
			"The Java debug adapter comes from jdtls, open a Java file of the project first",
			vim.log.levels.ERROR
		)
		return
	end
	dap.run({
		type = "java",
		request = "attach",
		name = "Attach to port " .. port,
		hostName = "127.0.0.1",
		port = port,
	})
end

--- Attaches the debugger as soon as the JVM listens on the port.
---@param port integer
function M.attach_when_ready(port)
	wait_for_port(port, 120000, function()
		M.attach(port)
	end)
end

--- Registers the run configurations as overseer templates.
function M.register()
	require("overseer").register_template({
		name = "Java run configurations",
		generator = function(_)
			local root = project.root(0)
			if not root then
				return "Not a Maven or Gradle project"
			end
			local result = {}
			for _, configuration in ipairs(M.configurations(root)) do
				local variants = configuration.type == "tomcat" and { false, true } or { false }
				for _, debug in ipairs(variants) do
					table.insert(result, {
						name = configuration.name .. (debug and " [debug]" or ""),
						desc = configuration.source,
						builder = function()
							return M.task(root, configuration, debug)
						end,
					})
				end
			end
			return result
		end,
	})
end

-- selected server per project root, like the run configuration selector in IntelliJ
local selected = {}

local function selection_file()
	return vim.fn.stdpath("state") .. "/java-selected-servers.json"
end

local function load_selection()
	local content = project.read_file(selection_file())
	local ok, stored = pcall(vim.json.decode, content or "")
	selected = ok and type(stored) == "table" and stored or {}
end

local function save_selection()
	vim.fn.mkdir(vim.fs.dirname(selection_file()), "p")
	vim.fn.writefile({ vim.json.encode(selected) }, selection_file())
end

local function servers(root)
	return vim.tbl_filter(function(configuration)
		return configuration.type == "tomcat"
	end, M.configurations(root))
end

--- Lets the user choose the server of the project.
---@param root string
---@param callback? fun(configuration: table)
function M.select_server(root, callback)
	local candidates = servers(root)
	if #candidates == 0 then
		vim.notify("No Tomcat run configuration, add one with :JavaSettings", vim.log.levels.WARN)
		return
	end
	vim.ui.select(candidates, {
		prompt = "Server",
		format_item = function(configuration)
			return string.format("%s (%s)", configuration.name, configuration.source)
		end,
	}, function(configuration)
		if configuration then
			selected[root] = configuration.name
			save_selection()
			if callback then
				callback(configuration)
			end
		end
	end)
end

local function with_server(callback)
	local root = current_root()
	if not root then
		return
	end
	if vim.tbl_isempty(selected) then
		load_selection()
	end
	for _, configuration in ipairs(servers(root)) do
		if configuration.name == selected[root] then
			callback(root, configuration)
			return
		end
	end
	M.select_server(root, function(configuration)
		callback(root, configuration)
	end)
end

local function server_task(configuration)
	for _, task in ipairs(require("overseer").list_tasks({})) do
		if task.name == configuration.name and task.metadata.server then
			return task
		end
	end
	return nil
end

local function build_war(root, configuration, on_success)
	if configuration.war then
		vim.notify(configuration.name .. " deploys " .. configuration.war .. ", there is nothing to build")
		if on_success then
			on_success()
		end
		return
	end
	local args = { "package", "-DskipTests" }
	if configuration.war_module then
		vim.list_extend(args, { "-pl", configuration.war_module, "-am" })
	end
	local definition = tasks.task(0, "Build WAR (" .. (configuration.war_module or vim.fs.basename(root)) .. ")", args)
	local task = require("overseer").new_task(definition)
	if on_success then
		task:subscribe("on_complete", function(_, status)
			if status == "SUCCESS" then
				vim.schedule(on_success)
			end
			return true
		end)
	end
	task:start()
end

local subcommands = {
	start = function()
		with_server(function(root, configuration)
			M.run(root, configuration, false)
		end)
	end,
	debug = function()
		with_server(function(root, configuration)
			M.run(root, configuration, true)
		end)
	end,
	stop = function()
		with_server(function(_, configuration)
			local task = server_task(configuration)
			if task and task:is_running() then
				task:stop()
			end
		end)
	end,
	build = function()
		with_server(function(root, configuration)
			build_war(root, configuration)
		end)
	end,
	rebuild = function()
		with_server(function(root, configuration)
			build_war(root, configuration, function()
				M.run(root, configuration, true)
			end)
		end)
	end,
	log = function()
		with_server(function(_, configuration)
			local task = server_task(configuration)
			if task then
				require("overseer").run_action(task, "open vsplit")
			else
				vim.notify(configuration.name .. " is not running", vim.log.levels.WARN)
			end
		end)
	end,
	attach = function()
		with_server(function(_, configuration)
			M.attach(configuration.debug_port or 5005)
		end)
	end,
	open = function()
		with_server(function(_, configuration)
			local task = server_task(configuration)
			local url = task and task.metadata.url
				or string.format(
					"http://localhost:%d%s",
					configuration.http_port or 8080,
					configuration.context_path or "/"
				)
			vim.ui.open(url)
		end)
	end,
	select = function()
		local root = current_root()
		if root then
			M.select_server(root)
		end
	end,
}

--- Creates the :JavaServer command.
function M.create_command()
	vim.api.nvim_create_user_command("JavaServer", function(args)
		local action = subcommands[args.args ~= "" and args.args or "debug"]
		if not action then
			vim.notify("Unknown subcommand " .. args.args, vim.log.levels.ERROR)
			return
		end
		action()
	end, {
		nargs = "?",
		complete = function()
			return vim.tbl_keys(subcommands)
		end,
		desc = "Run the selected server of the project",
	})
end

return M
