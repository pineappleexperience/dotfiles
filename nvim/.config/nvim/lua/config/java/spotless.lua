-- conform.nvim formatter that formats a buffer with the project's own Spotless configuration.
local M = {}

local project = require("config.java.project")
local settings = require("config.java.settings")

-- per root: the project directory whose Spotless configuration covered the last formatted file
local covering_dir = {}

local function candidate_dirs(root, filename)
	local dirs = {}
	local dir = vim.fs.dirname(filename)
	while dir and vim.startswith(dir, root) do
		for _, file in ipairs({ "pom.xml", "build.gradle", "build.gradle.kts" }) do
			if vim.uv.fs_stat(dir .. "/" .. file) then
				table.insert(dirs, dir)
				break
			end
		end
		if dir == root then
			break
		end
		dir = vim.fs.dirname(dir)
	end
	local cached = covering_dir[root]
	if cached and vim.tbl_contains(dirs, cached) then
		table.sort(dirs, function(a, b)
			return a == cached and b ~= cached
		end)
	end
	return dirs
end

local function command(root, dir, filename)
	local cmd = project.build_command(root)
	if project.build_tool(root) == "gradle" then
		local task = dir == root and "spotlessApply" or ":" .. dir:sub(#root + 2):gsub("/", ":") .. ":spotlessApply"
		return {
			cmd,
			"--quiet",
			task,
			"-PspotlessIdeHook=" .. filename,
			"-PspotlessIdeHookUseStdIn",
			"-PspotlessIdeHookUseStdOut",
		}
	end
	return {
		cmd,
		"-q",
		"-B",
		"-N",
		"spotless:apply",
		"-DspotlessIdeHook=" .. filename,
		"-DspotlessIdeHookUseStdIn",
		"-DspotlessIdeHookUseStdOut",
	}
end

--- Whether the project of the file configures Spotless.
---@param filename string
---@return boolean
function M.available(filename)
	local root = project.root(filename)
	return root ~= nil and project.build_files_mention(root, project.module_dir(filename) or root, "spotless")
end

M.formatter = {
	meta = {
		url = "https://github.com/diffplug/spotless",
		description = "Formats with the Spotless configuration of the Maven or Gradle project.",
	},
	condition = function(_, ctx)
		return M.available(ctx.filename)
	end,
	format = function(_, ctx, lines, callback)
		local root = project.root(ctx.filename)
		local dirs = candidate_dirs(root, ctx.filename)
		local input = table.concat(lines, "\n") .. "\n"
		local env = settings.env(root)

		local function try(index)
			local dir = dirs[index]
			if not dir then
				callback("Spotless does not cover " .. ctx.filename)
				return
			end
			vim.system(
				command(root, dir, ctx.filename),
				{ cwd = dir, stdin = input, env = env, text = true },
				function(out)
					vim.schedule(function()
						if out.code ~= 0 then
							callback(vim.trim(out.stdout .. "\n" .. out.stderr))
						elseif out.stderr:find("IS DIRTY", 1, true) then
							covering_dir[root] = dir
							callback(nil, vim.split((out.stdout:gsub("\n$", "")), "\n", { plain = true }))
						elseif out.stderr:find("IS CLEAN", 1, true) then
							covering_dir[root] = dir
							callback(nil, lines)
						elseif out.stderr:find("DID NOT CONVERGE", 1, true) then
							callback("Spotless did not converge for " .. ctx.filename)
						else
							try(index + 1)
						end
					end)
				end
			)
		end

		try(1)
	end,
}

return M
