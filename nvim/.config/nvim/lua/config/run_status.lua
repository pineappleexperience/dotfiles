-- Running tasks, servers and debug sessions for the statusline, like the run widget of IntelliJ.
local M = {}

local icons = {
	server = "󰒋",
	task = "",
	debug = "",
	paused = "",
	failed = "",
}

local function truncate(text, length)
	return #text > length and text:sub(1, length - 1) .. "…" or text
end

local function task_parts()
	local overseer = package.loaded["overseer"]
	if not overseer then
		return {}
	end
	local parts = {}
	for _, task in ipairs(overseer.list_tasks({ status = { overseer.STATUS.RUNNING } })) do
		local icon = task.metadata and task.metadata.server and icons.server or icons.task
		table.insert(parts, icon .. " " .. truncate(task.name, 40))
	end
	-- a failed task stays visible until it is restarted or disposed
	for _, task in ipairs(overseer.list_tasks({ status = { overseer.STATUS.FAILURE } })) do
		table.insert(parts, icons.failed .. " " .. truncate(task.name, 40))
	end
	return parts
end

local function debug_part()
	local dap = package.loaded["dap"]
	local session = dap and dap.session()
	if not session then
		return nil
	end
	local name = session.config and session.config.name or "debug"
	if session.stopped_thread_id then
		return icons.paused .. " " .. name
	end
	return icons.debug .. " " .. name
end

--- Text of the run indicator, empty when nothing runs.
---@return string
function M.text()
	local parts = task_parts()
	local debug = debug_part()
	if debug then
		table.insert(parts, debug)
	end
	return table.concat(parts, "  ")
end

--- Highlight group of the indicator: error when something failed, warning while debugging, ok while running.
---@return string
function M.highlight()
	local overseer = package.loaded["overseer"]
	if overseer and #overseer.list_tasks({ status = { overseer.STATUS.FAILURE } }) > 0 then
		return "DiagnosticError"
	end
	if debug_part() then
		return "DiagnosticWarn"
	end
	return "DiagnosticOk"
end

--- Opens the task list.
function M.click()
	vim.cmd("OverseerToggle!")
end

return M
