-- Starts jdtls through nvim-jdtls for Maven and Gradle projects.
local M = {}

local project = require("config.java.project")

local function mason_package(name)
	return vim.fn.expand("$MASON/packages/" .. name)
end

local function workspace_dir(root)
	local name = vim.fs.basename(root) .. "-" .. vim.fn.sha256(root):sub(1, 8)
	return vim.fn.stdpath("cache") .. "/jdtls/workspaces/" .. name
end

local function bundles(root)
	local result = vim.fn.glob(
		mason_package("java-debug-adapter") .. "/extension/server/com.microsoft.java.debug.plugin-*.jar",
		false,
		true
	)
	-- the test runner jar and the jacoco agent are not jdtls extensions
	local excluded = { "com.microsoft.java.test.runner-jar-with-dependencies.jar", "jacocoagent.jar" }
	local jdtls_plugins = mason_package("jdtls") .. "/plugins/"
	for _, jar in ipairs(vim.fn.glob(mason_package("java-test") .. "/extension/server/*.jar", false, true)) do
		local name = vim.fs.basename(jar)
		-- a bundle that jdtls already contains cannot be installed twice and breaks loading all extensions
		if not vim.tbl_contains(excluded, name) and not vim.uv.fs_stat(jdtls_plugins .. name) then
			table.insert(result, jar)
		end
	end
	if M.uses_spring_boot(root) then
		local ok, spring_boot = pcall(require, "spring_boot")
		if ok then
			vim.list_extend(result, spring_boot.java_extensions())
		end
	end
	return result
end

local spring_boot_cache = {}

--- Whether the project depends on Spring Boot.
---@param root string
---@return boolean
function M.uses_spring_boot(root)
	if spring_boot_cache[root] == nil then
		local ok, util = pcall(require, "spring_boot.util")
		spring_boot_cache[root] = ok and util.has_spring_boot_dependency(root) or false
	end
	return spring_boot_cache[root]
end

local function runtimes()
	local result = {}
	for major, jdk in pairs(project.jdks()) do
		if major >= 8 then
			table.insert(result, { name = major == 8 and "JavaSE-1.8" or "JavaSE-" .. major, path = jdk.home })
		end
	end
	table.sort(result, function(a, b)
		return a.name < b.name
	end)
	return result
end

local function java_executable()
	local home = vim.env.JDTLS_JAVA_HOME or project.newest_jdk_home(21)
	return home and home .. "/bin/java" or "java"
end

local function settings()
	local maven_settings = vim.fn.expand("~/.m2/settings.xml")
	return {
		java = {
			configuration = {
				runtimes = runtimes(),
				updateBuildConfiguration = "automatic",
				maven = {
					userSettings = vim.uv.fs_stat(maven_settings) and maven_settings or nil,
					notCoveredPluginExecutionSeverity = "ignore",
				},
			},
			import = {
				exclusions = {
					"**/node_modules/**",
					"**/.yarn/**",
					"**/.metadata/**",
					"**/archetype-resources/**",
					"**/META-INF/maven/**",
				},
			},
			eclipse = { downloadSources = true },
			maven = { downloadSources = true },
			format = { enabled = true },
			saveActions = { organizeImports = false },
			signatureHelp = { enabled = true },
			contentProvider = { preferred = "fernflower" },
			referencesCodeLens = { enabled = true },
			implementationsCodeLens = { enabled = true },
			inlayHints = { parameterNames = { enabled = "all" } },
			completion = {
				favoriteStaticMembers = {
					"org.assertj.core.api.Assertions.*",
					"org.junit.jupiter.api.Assertions.*",
					"org.junit.jupiter.api.Assumptions.*",
					"org.mockito.Mockito.*",
					"org.mockito.ArgumentMatchers.*",
					"org.mockito.BDDMockito.*",
					"java.util.Objects.requireNonNull",
					"java.util.Objects.requireNonNullElse",
				},
				filteredTypes = {
					"com.sun.*",
					"io.micrometer.shaded.*",
					"java.awt.*",
					"jdk.*",
					"sun.*",
				},
			},
			sources = {
				organizeImports = {
					starThreshold = 9999,
					staticStarThreshold = 9999,
				},
			},
			codeGeneration = {
				toString = {
					template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}",
				},
				hashCodeEquals = { useJava7Objects = true },
				useBlocks = true,
			},
		},
	}
end

local function keymaps(bufnr)
	local jdtls = require("jdtls")
	local function map(mode, keys, func, desc)
		vim.keymap.set(mode, keys, func, { buffer = bufnr, desc = "Java: " .. desc })
	end

	map("n", "<leader>Jo", jdtls.organize_imports, "[O]rganize imports")
	map("n", "<leader>Jv", jdtls.extract_variable, "Extract [V]ariable")
	map("x", "<leader>Jv", function()
		jdtls.extract_variable(true)
	end, "Extract [V]ariable")
	map("n", "<leader>JC", jdtls.extract_constant, "Extract [C]onstant")
	map("x", "<leader>JC", function()
		jdtls.extract_constant(true)
	end, "Extract [C]onstant")
	map("x", "<leader>Jm", function()
		jdtls.extract_method(true)
	end, "Extract [M]ethod")
	map("n", "<leader>Js", jdtls.super_implementation, "Go to [S]uper implementation")
	map("n", "<leader>Jg", function()
		vim.lsp.buf.code_action({ context = { only = { "source" }, diagnostics = {} } })
	end, "[G]enerate (getters, constructors, toString, ...)")
	map("n", "<leader>Jt", jdtls.test_nearest_method, "Debug nearest [t]est method")
	map("n", "<leader>JT", jdtls.test_class, "Debug [T]est class")
	map("n", "<leader>Jp", jdtls.pick_test, "[P]ick test to debug")
	map("n", "<leader>Ju", "<cmd>JdtUpdateConfig<cr>", "[U]pdate project configuration")
	map("n", "<leader>Jb", function()
		jdtls.compile("full")
	end, "Re[b]uild workspace")
	map("n", "<leader>Jr", "<cmd>JdtRestart<cr>", "[R]estart jdtls")
	map("n", "<leader>Jw", function()
		local root = project.root(bufnr)
		vim.ui.select({ "yes", "no" }, {
			prompt = "Delete the jdtls workspace of " .. root .. " and restart?",
		}, function(choice)
			if choice == "yes" then
				for _, client in ipairs(vim.lsp.get_clients({ name = "jdtls" })) do
					client:stop(true)
				end
				vim.fn.delete(workspace_dir(root), "rf")
				vim.defer_fn(function()
					vim.cmd.edit()
				end, 1000)
			end
		end)
	end, "Clean [W]orkspace and restart")
	map("n", "<leader>tl", function()
		vim.lsp.codelens.enable(not vim.lsp.codelens.is_enabled({ bufnr = bufnr }), { bufnr = bufnr })
	end, "[T]oggle code [L]ens")
end

local notified = {}

-- client id per project root, for clients that are still initializing
local started = {}

local function start(root, module_dir, start_opts)
	local jdtls_home = mason_package("jdtls")
	local lombok, lombok_source = project.lombok(root, module_dir, jdtls_home .. "/lombok.jar")
	if not notified[root] then
		notified[root] = true
		vim.notify(string.format("jdtls: %s, %s", vim.fs.basename(root), lombok_source), vim.log.levels.INFO)
	end

	local cmd = {
		java_executable(),
		"-Declipse.application=org.eclipse.jdt.ls.core.id1",
		"-Dosgi.bundles.defaultStartLevel=4",
		"-Declipse.product=org.eclipse.jdt.ls.core.product",
		"-Dlog.level=WARNING",
		-- keep .project, .classpath and .settings in the jdtls workspace instead of the project
		"-Djava.import.generatesMetadataFilesAtProjectRoot=false",
		-- m2e would otherwise rewrite Eclipse launch configurations (*.launch) in the project
		"-Dm2e.process.test.configuration=false",
		"-Xms1g",
		"-Xmx" .. (vim.g.jdtls_max_heap or "6g"),
		"-XX:+UseG1GC",
		"-XX:+UseStringDeduplication",
		"--add-modules=ALL-SYSTEM",
		"--add-opens",
		"java.base/java.util=ALL-UNNAMED",
		"--add-opens",
		"java.base/java.lang=ALL-UNNAMED",
		"-javaagent:" .. lombok,
		"-jar",
		vim.fn.glob(jdtls_home .. "/plugins/org.eclipse.equinox.launcher_*.jar"),
		"-configuration",
		jdtls_home .. "/config_" .. (jit.os == "OSX" and "mac" or "linux") .. (jit.arch == "arm64" and "_arm" or ""),
		"-data",
		workspace_dir(root),
	}

	local extendedClientCapabilities = vim.deepcopy(require("jdtls").extendedClientCapabilities)
	extendedClientCapabilities.resolveAdditionalTextEditsSupport = true

	local client_id = require("jdtls").start_or_attach({
		cmd = cmd,
		root_dir = root,
		settings = settings(),
		capabilities = require("blink.cmp").get_lsp_capabilities(),
		init_options = {
			bundles = bundles(root),
			extendedClientCapabilities = extendedClientCapabilities,
		},
		on_attach = function(_, attached_bufnr)
			keymaps(attached_bufnr)
		end,
	}, {
		dap = { hotcodereplace = "auto", config_overrides = {} },
	}, start_opts)
	started[root] = client_id or started[root]
	return client_id
end

--- Starts jdtls for the current buffer or attaches it to the running instance of its project.
function M.start()
	local bufnr = vim.api.nvim_get_current_buf()
	local root = project.root(bufnr)
	if root then
		start(root, project.module_dir(bufnr))
	end
end

--- The running jdtls client of the project.
---@param root string
---@return vim.lsp.Client|nil
function M.client(root)
	for _, client in ipairs(vim.lsp.get_clients({ name = "jdtls" })) do
		if client.root_dir == root then
			return client
		end
	end
	-- a client that is still initializing is not listed yet
	local client = started[root] and vim.lsp.get_client_by_id(started[root])
	return client and not client:is_stopped() and client or nil
end

--- Starts jdtls for a project without a Java buffer. Buffers opened later attach to it.
---@param root string
function M.start_project(root)
	if M.client(root) or not project.build_tool(root) then
		return
	end
	-- nvim-jdtls needs a buffer with a file URI to start, an unnamed scratch buffer has one. Deleting it
	-- afterwards keeps nvim-jdtls from querying project settings for it.
	local placeholder = vim.api.nvim_create_buf(false, true)
	start(root, root, { bufnr = placeholder, attach = false })
	vim.api.nvim_buf_delete(placeholder, { force = true })
end

return M
