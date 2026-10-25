-- Navigation from EL expressions in Facelets (#{bean.property}) to the CDI or JSF managed bean.
local M = {}

local project = require("config.java.project")

-- the dotted identifier chain under the cursor inside an EL expression, e.g. { "bean", "property" } and the index
local function el_chain_at_cursor()
	local line = vim.api.nvim_get_current_line()
	local col = vim.api.nvim_win_get_cursor(0)[2] + 1
	local start = 1
	while true do
		local s, e = line:find("[#$]%b{}", start)
		if not s then
			return nil
		end
		if col >= s and col <= e then
			local pos = s
			while pos <= e do
				local cs, ce = line:find("[%a_][%w_]*%f[^%w_]", pos)
				if not cs or cs > e then
					break
				end
				local chain_end = ce
				while line:sub(chain_end + 1, chain_end + 1) == "." do
					local _, next_end = line:find("^[%a_][%w_]*", chain_end + 2)
					if not next_end then
						break
					end
					chain_end = next_end
				end
				if col >= cs and col <= chain_end then
					local parts = vim.split(line:sub(cs, chain_end), ".", { plain = true })
					local index, offset = 1, cs
					for i, part in ipairs(parts) do
						if col >= offset and col < offset + #part + 1 then
							index = i
							break
						end
						offset = offset + #part + 1
					end
					return parts, index
				end
				pos = chain_end + 1
			end
			return nil
		end
		start = e + 1
	end
end

local function rg_files(root, pattern)
	local result = vim.system({ "rg", "-l", "--glob", "*.java", "-e", pattern, root }, { text = true }):wait()
	return vim.split(result.stdout, "\n", { trimempty = true })
end

local function find_bean(root, name)
	local quoted = '"' .. name .. '"'
	local files = rg_files(root, [[@(Named|ManagedBean|Component|Service)\((value\s*=\s*|name\s*=\s*)?]] .. quoted)
	if #files > 0 then
		return files
	end
	local class = name:sub(1, 1):upper() .. name:sub(2)
	local result = vim.system({ "rg", "--files", "--glob", "**/" .. class .. ".java", root }, { text = true }):wait()
	return vim.split(result.stdout, "\n", { trimempty = true })
end

local function jump_to_member(member)
	local capitalized = member:sub(1, 1):upper() .. member:sub(2)
	-- declarations only: a type or modifiers before the name, no call or assignment on the line before it
	local declaration = [[\v^\s*[^=().;]*\s]]
	local patterns = {
		declaration .. [[(get|is)]] .. capitalized .. [[\s*\(]],
		declaration .. member .. [[\s*\(]],
		declaration .. member .. [=[\s*[;=]]=],
	}
	for _, pattern in ipairs(patterns) do
		if vim.fn.search(pattern, "w") > 0 then
			return
		end
	end
end

local function open(file, member)
	vim.cmd.edit(vim.fn.fnameescape(file))
	if member then
		jump_to_member(member)
	end
end

--- Jumps from the EL expression under the cursor to its bean, falls back to LSP definition.
function M.goto_definition()
	local parts, index = el_chain_at_cursor()
	local root = project.root(0)
	if not parts or not root then
		if #vim.lsp.get_clients({ bufnr = 0, method = "textDocument/definition" }) > 0 then
			vim.lsp.buf.definition()
		else
			vim.cmd.normal({ "gd", bang = true })
		end
		return
	end
	local member = index >= 2 and parts[2] or nil
	local files = find_bean(root, parts[1])
	if #files == 0 then
		vim.notify("No bean named " .. parts[1], vim.log.levels.WARN)
	elseif #files == 1 then
		open(files[1], member)
	else
		vim.ui.select(files, {
			prompt = "Bean " .. parts[1],
			format_item = function(file)
				return file:sub(#root + 2)
			end,
		}, function(file)
			if file then
				open(file, member)
			end
		end)
	end
end

return M
