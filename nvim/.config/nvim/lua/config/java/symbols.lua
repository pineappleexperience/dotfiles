-- Workspace symbol search that also works in buffers without a language server, e.g. right after startup.
local M = {}

local project = require("config.java.project")

local function requester(client, opts)
	local channel = require("plenary.async.control").channel
	local pending
	return function(prompt)
		if pending then
			client:cancel_request(pending)
		end
		local tx, rx = channel.oneshot()
		local _, request_id = client:request("workspace/symbol", { query = prompt }, function(err, result)
			tx(err, result)
		end)
		pending = request_id
		local err, result = rx()
		pending = nil
		if err or not result then
			return {}
		end
		return vim.lsp.util.symbols_to_items(result, opts.bufnr, client.offset_encoding)
	end
end

--- Searches classes, methods and fields of the workspace.
function M.pick()
	local builtin = require("telescope.builtin")
	local bufnr = vim.api.nvim_get_current_buf()
	if #vim.lsp.get_clients({ bufnr = bufnr, method = "workspace/symbol" }) > 0 then
		builtin.lsp_dynamic_workspace_symbols()
		return
	end

	local root = project.root(bufnr)
	if not root or not project.build_tool(root) then
		vim.notify("No language server for workspace symbols", vim.log.levels.WARN)
		return
	end
	local jdtls = require("config.java.jdtls")
	if not jdtls.client(root) then
		jdtls.start_project(root)
		vim.notify("jdtls is starting, results appear once the project is imported")
	end
	local client = jdtls.client(root)
	if not client then
		return
	end
	if not client.initialized then
		vim.notify("jdtls is still starting, try again in a moment")
		return
	end

	local opts = { bufnr = bufnr }
	local conf = require("telescope.config").values
	require("telescope.pickers")
		.new(opts, {
			prompt_title = "Java symbols",
			finder = require("telescope.finders").new_dynamic({
				entry_maker = require("telescope.make_entry").gen_from_lsp_symbols(opts),
				fn = requester(client, opts),
			}),
			previewer = conf.qflist_previewer(opts),
			sorter = conf.generic_sorter(opts),
		})
		:find()
end

return M
