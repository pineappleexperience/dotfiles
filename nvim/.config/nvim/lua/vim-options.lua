vim.cmd("set expandtab")
vim.cmd("set tabstop=2")
vim.cmd("set softtabstop=2")
vim.cmd("set shiftwidth=2")

-- Set leader key
vim.g.mapleader = " "

-- Line numbering
vim.opt.number = true
vim.opt.relativenumber = true

-- Keybindings
local map = vim.api.nvim_set_keymap
local opts = { noremap = true, silent = true }

-- Insert blank lines above/below
-- map("n", "<S-Enter>", "O<Esc>", opts)
-- map("n", "<CR>", "o<Esc>", opts)

-- Move lines up and down
map("n", "<C-j>", ":m +1<CR>", opts)
map("n", "<C-k>", ":m -2<CR>", opts)
map("i", "<C-j>", "<Esc>:m +1<CR>gi", opts)
map("i", "<C-k>", "<Esc>:m -2<CR>gi", opts)

-- Clipboard (Use system clipboard)
map("v", "<leader>y", '"+y', opts)
map("v", "<leader>d", '"+d', opts)
map("n", "<leader>y", '"+yy', opts)
map("n", "<leader>p", '"+p', opts)
map("n", "<leader>P", '"+P', opts)
map("v", "<leader>p", '"+p', opts)
map("v", "<leader>P", '"+P', opts)

-- Smooth scrolling
map("n", "<leader>d", "<C-d>", opts)
map("n", "<leader>u", "<C-u>", opts)
map("v", "<leader>d", "<C-d>", opts)
map("v", "<leader>u", "<C-u>", opts)

-- (Un)checking markdown checklist items
vim.keymap.set('n', '<leader>c', function()
  local line = vim.api.nvim_get_current_line()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row, col = cursor[1], cursor[2]

  local checked = line:find("%[x%]")
  local unchecked = line:find("%[%s%]")

  if unchecked then
    line = line:gsub("%[%s%]", "[x]", 1)
  elseif checked then
    line = line:gsub("%[x%]", "[ ]", 1)
  end

  vim.api.nvim_set_current_line(line)
end, { desc = "Toggle markdown checkbox" })

