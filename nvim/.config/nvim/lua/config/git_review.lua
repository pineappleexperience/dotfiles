-- Reviewing branches, GitLab merge requests and GitHub pull requests with diffview.nvim.
local M = {}

local function run(cmd)
	local result = vim.system(cmd, { text = true }):wait()
	if result.code ~= 0 then
		return nil, vim.trim(result.stderr ~= "" and result.stderr or result.stdout)
	end
	return vim.trim(result.stdout)
end

local function host_cli()
	local remote = run({ "git", "remote", "get-url", "origin" }) or ""
	if remote:find("github.com", 1, true) then
		return vim.fn.executable("gh") == 1 and "gh" or nil
	end
	return vim.fn.executable("glab") == 1 and "glab" or nil
end

local function default_branch()
	local head = run({ "git", "symbolic-ref", "--short", "refs/remotes/origin/HEAD" })
	if head then
		return (head:gsub("^origin/", ""))
	end
	for _, branch in ipairs({ "main", "master", "develop" }) do
		if run({ "git", "rev-parse", "--verify", "--quiet", "origin/" .. branch }) then
			return branch
		end
	end
	return "main"
end

--- Target branch of the merge request or pull request of the current branch, else the default branch.
---@return string
function M.target_branch()
	local cli = host_cli()
	if cli == "glab" then
		local json = run({ "glab", "mr", "view", "-F", "json" })
		local ok, mr = pcall(vim.json.decode, json or "")
		if ok and type(mr) == "table" and mr.target_branch then
			return mr.target_branch
		end
	elseif cli == "gh" then
		local json = run({ "gh", "pr", "view", "--json", "baseRefName" })
		local ok, pr = pcall(vim.json.decode, json or "")
		if ok and type(pr) == "table" and pr.baseRefName then
			return pr.baseRefName
		end
	end
	return default_branch()
end

--- Shows all changes of the current branch since it forked from the target branch.
---@param target? string branch to compare against, detected when nil
function M.review(target)
	target = target and target ~= "" and target or M.target_branch()
	vim.notify("Fetching origin/" .. target)
	vim.system({ "git", "fetch", "origin", target }, { text = true }, function(result)
		vim.schedule(function()
			if result.code ~= 0 then
				vim.notify("git fetch failed, comparing with the local origin/" .. target, vim.log.levels.WARN)
			end
			vim.cmd("DiffviewOpen origin/" .. target .. "...HEAD --imply-local")
		end)
	end)
end

local function open_requests(cli)
	if cli == "glab" then
		local json, err = run({ "glab", "mr", "list", "-F", "json" })
		if not json then
			return nil, err
		end
		return vim.tbl_map(function(mr)
			return {
				id = mr.iid,
				title = mr.title,
				author = mr.author and mr.author.username,
				target = mr.target_branch,
			}
		end, vim.json.decode(json))
	end
	local json, err = run({ "gh", "pr", "list", "--json", "number,title,author,baseRefName" })
	if not json then
		return nil, err
	end
	return vim.tbl_map(function(pr)
		return { id = pr.number, title = pr.title, author = pr.author and pr.author.login, target = pr.baseRefName }
	end, vim.json.decode(json))
end

--- Picks an open merge request or pull request, checks it out and reviews it.
function M.pick_request()
	local cli = host_cli()
	if not cli then
		vim.notify("Install glab (GitLab) or gh (GitHub) to review merge requests", vim.log.levels.ERROR)
		return
	end
	if (run({ "git", "status", "--porcelain", "--untracked-files=no" }) or "") ~= "" then
		vim.notify("Commit or stash your changes before checking out a merge request", vim.log.levels.ERROR)
		return
	end
	local requests, err = open_requests(cli)
	if not requests then
		vim.notify(err or "Could not list merge requests", vim.log.levels.ERROR)
		return
	end
	vim.ui.select(requests, {
		prompt = "Review",
		format_item = function(request)
			return string.format("!%s %s (%s → %s)", request.id, request.title, request.author or "?", request.target)
		end,
	}, function(request)
		if not request then
			return
		end
		local checkout = cli == "glab" and { "glab", "mr", "checkout", tostring(request.id) }
			or { "gh", "pr", "checkout", tostring(request.id) }
		local _, checkout_err = run(checkout)
		if checkout_err then
			vim.notify(checkout_err, vim.log.levels.ERROR)
			return
		end
		vim.cmd.checktime()
		M.review(request.target)
	end)
end

--- Opens the merge request or pull request of the current branch in the browser.
function M.open_in_browser()
	local cli = host_cli()
	if cli == "glab" then
		run({ "glab", "mr", "view", "--web" })
	elseif cli == "gh" then
		run({ "gh", "pr", "view", "--web" })
	end
end

return M
