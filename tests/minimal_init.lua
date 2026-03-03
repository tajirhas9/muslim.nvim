local plenary_path = vim.fn.stdpath("data") .. "/lazy/plenary.nvim"
local plugin_path  = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h")

vim.opt.rtp:prepend(plugin_path)
vim.opt.rtp:prepend(plenary_path)

vim.cmd("runtime! plugin/plenary.vim")
