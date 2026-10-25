-- Project detection for Maven and Gradle projects: root, modules, build tool, installed JDKs and Lombok.
local M = {}

local uv = vim.uv

local build_files = { "pom.xml", "build.gradle", "build.gradle.kts" }

local function exists(path)
	return path ~= nil and uv.fs_stat(path) ~= nil
end

function M.read_file(path)
	local fd = io.open(path, "r")
	if not fd then
		return nil
	end
	local content = fd:read("*a")
	fd:close()
	return content
end

local function buf_path(source)
	if type(source) == "string" then
		return source
	end
	local name = vim.api.nvim_buf_get_name(source or 0)
	if name == "" or name:match("^%a+://") then
		return uv.cwd()
	end
	return name
end

--- Root directory of the project that contains the given buffer or path.
---@param source? integer|string buffer number or path, defaults to the current buffer
---@return string|nil
function M.root(source)
	local path = buf_path(source)
	local root = vim.fs.root(path, {
		{ "mvnw", "gradlew", ".mvn", "settings.gradle", "settings.gradle.kts" },
		".git",
	})
	if root then
		return root
	end
	local top
	local dirs = vim.fn.isdirectory(path) == 1 and { path } or {}
	for dir in vim.fs.parents(path) do
		table.insert(dirs, dir)
	end
	for _, dir in ipairs(dirs) do
		for _, file in ipairs(build_files) do
			if exists(vim.fs.joinpath(dir, file)) then
				top = dir
			end
		end
	end
	return top
end

--- Build tool of the project root.
---@param root string
---@return "maven"|"gradle"|nil
function M.build_tool(root)
	if exists(root .. "/pom.xml") then
		return "maven"
	end
	for _, file in ipairs({ "build.gradle", "build.gradle.kts", "settings.gradle", "settings.gradle.kts" }) do
		if exists(root .. "/" .. file) then
			return "gradle"
		end
	end
	return nil
end

--- Directory of the Maven or Gradle module that contains the given buffer or path.
---@param source? integer|string
---@return string|nil
function M.module_dir(source)
	local root = M.root(source)
	if not root then
		return nil
	end
	local dir = vim.fs.root(buf_path(source), build_files)
	if dir and vim.startswith(dir, root) then
		return dir
	end
	return root
end

--- Path of the module relative to the root, nil for the root itself.
---@param root string
---@param module_dir string
---@return string|nil
function M.relative_module(root, module_dir)
	if module_dir == root then
		return nil
	end
	return module_dir:sub(#root + 2)
end

--- Command that runs the build tool, prefers the project's wrapper.
---@param root string
---@return string
function M.build_command(root)
	if M.build_tool(root) == "gradle" then
		return exists(root .. "/gradlew") and root .. "/gradlew" or "gradle"
	end
	return exists(root .. "/mvnw") and root .. "/mvnw" or "mvn"
end

--- Local Maven repository, respects `localRepository` in `~/.m2/settings.xml`.
---@return string
function M.maven_repository()
	local settings = M.read_file(vim.fn.expand("~/.m2/settings.xml"))
	local repo = settings and settings:match("<localRepository>%s*(.-)%s*</localRepository>")
	if repo and repo ~= "" then
		return vim.fn.expand(repo)
	end
	return vim.fn.expand("~/.m2/repository")
end

local function version_parts(version)
	local parts = {}
	for number in version:gmatch("%d+") do
		table.insert(parts, tonumber(number))
	end
	-- "1.8.0_402" is Java 8
	if parts[1] == 1 and parts[2] then
		table.remove(parts, 1)
	end
	return parts
end

local function newer(a, b)
	local pa, pb = version_parts(a), version_parts(b)
	for i = 1, math.max(#pa, #pb) do
		local x, y = pa[i] or 0, pb[i] or 0
		if x ~= y then
			return x > y
		end
	end
	return false
end

local function jdk_candidates()
	local homes = {}
	local patterns = {
		"/Library/Java/JavaVirtualMachines/*/Contents/Home",
		"~/Library/Java/JavaVirtualMachines/*/Contents/Home",
		"/usr/lib/jvm/*",
		"~/.sdkman/candidates/java/*",
		"~/.local/share/mise/installs/java/*",
		"~/.asdf/installs/java/*",
		"/opt/homebrew/opt/openjdk*/libexec/openjdk.jdk/Contents/Home",
	}
	for _, pattern in ipairs(patterns) do
		vim.list_extend(homes, vim.fn.glob((pattern:gsub("^~", vim.env.HOME)), false, true))
	end
	return homes
end

local jdks_cache

--- Installed JDKs, the newest installation per major version.
---@return table<integer, { home: string, version: string }>
function M.jdks()
	if jdks_cache then
		return jdks_cache
	end
	jdks_cache = {}
	for _, home in ipairs(jdk_candidates()) do
		local release = M.read_file(home .. "/release")
		local version = release and release:match('JAVA_VERSION="([^"]+)"')
		local real_home = uv.fs_realpath(home) or home
		if version and exists(real_home .. "/bin/java") then
			local major = version_parts(version)[1]
			local known = jdks_cache[major]
			if not known or newer(version, known.version) then
				jdks_cache[major] = { home = real_home, version = version }
			end
		end
	end
	return jdks_cache
end

--- Home of the installed JDK with the given major version.
---@param major integer|string|nil
---@return string|nil
function M.jdk_home(major)
	local jdk = major and M.jdks()[tonumber(major)]
	return jdk and jdk.home or nil
end

local function is_lts(major)
	return major == 8 or major == 11 or (major >= 17 and (major - 17) % 4 == 0)
end

--- Home of the newest installed JDK with at least the given major version, LTS releases are preferred.
---@param min_major integer
---@return string|nil
function M.newest_jdk_home(min_major)
	local best
	for major, jdk in pairs(M.jdks()) do
		if major >= min_major then
			local rank = (is_lts(major) and 1000 or 0) + major
			if not best or rank > best.rank then
				best = { rank = rank, home = jdk.home }
			end
		end
	end
	return best and best.home or nil
end

local function maven_property(content, name)
	return content:match("<" .. vim.pesc(name) .. ">%s*([^<%s]+)%s*</" .. vim.pesc(name) .. ">")
end

local function lombok_version_from_pom(content)
	local version = content:match("<artifactId>%s*lombok%s*</artifactId>%s*<version>%s*([^<%s]+)%s*</version>")
		or maven_property(content, "lombok.version")
	if version then
		local property = version:match("^%${(.+)}$")
		if property then
			version = maven_property(content, property)
		end
	end
	return version
end

local function lombok_version_from_gradle(content)
	return content:match("org%.projectlombok:lombok:([%w%.%-]+)") or content:match("lombok%s*=%s*[\"']([%w%.%-]+)[\"']")
end

local function lombok_jar(root, module_dir)
	local tool = M.build_tool(root)
	if tool == "maven" then
		for _, dir in ipairs({ module_dir, root }) do
			local content = dir and M.read_file(dir .. "/pom.xml")
			local version = content and lombok_version_from_pom(content)
			if version then
				return string.format(
					"%s/org/projectlombok/lombok/%s/lombok-%s.jar",
					M.maven_repository(),
					version,
					version
				),
					version
			end
		end
	elseif tool == "gradle" then
		for _, file in ipairs({ "build.gradle", "build.gradle.kts", "gradle/libs.versions.toml" }) do
			for _, dir in ipairs({ module_dir, root }) do
				local content = dir and M.read_file(dir .. "/" .. file)
				local version = content and lombok_version_from_gradle(content)
				if version then
					local jars = vim.fn.glob(
						string.format(
							"~/.gradle/caches/modules-2/files-2.1/org.projectlombok/lombok/%s/*/lombok-%s.jar",
							version,
							version
						),
						false,
						true
					)
					return jars[1], version
				end
			end
		end
	end
	return nil, nil
end

--- Lombok jar used as Java agent for jdtls. Prefers the version the project declares.
---@param root string
---@param module_dir? string
---@param fallback string jar to use when the project's Lombok cannot be found
---@return string jar
---@return string source short description where the jar comes from
function M.lombok(root, module_dir, fallback)
	local jar, version = lombok_jar(root, module_dir)
	if jar and exists(jar) then
		return jar, "project Lombok " .. version
	end
	if version then
		return fallback, "bundled Lombok, project Lombok " .. version .. " is not downloaded yet"
	end
	return fallback, "bundled Lombok"
end

--- Whether a build file between the module and the root mentions the given text.
---@param root string
---@param module_dir string
---@param text string
---@return boolean
function M.build_files_mention(root, module_dir, text)
	local dir = module_dir
	while dir and vim.startswith(dir, root) do
		for _, file in ipairs(build_files) do
			local content = M.read_file(dir .. "/" .. file)
			if content and content:find(text, 1, true) then
				return true
			end
		end
		if dir == root then
			break
		end
		dir = vim.fs.dirname(dir)
	end
	return false
end

return M
