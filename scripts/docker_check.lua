-- Run by the Docker build and CI after the config loads: fails if a language server, parser or the game is missing.
-- bootstrap.lua keeps going when an install fails, so without this a broken image would still build.
local function check()
  local missing = {}

  -- With no Mason registry the mapping is empty, so a server without a package counts as missing too
  local package_for = require('mason-lspconfig').get_mappings().lspconfig_to_package
  local registry = require 'mason-registry'
  for _, config in ipairs(vim.lsp.get_configs { enabled = true }) do
    local pkg = package_for[config.name]
    if not pkg or not registry.is_installed(pkg) then table.insert(missing, 'language server ' .. config.name) end
  end

  -- Ask nvim-treesitter what it installed: Neovim ships its own c, lua, markdown, query, vim and vimdoc parsers,
  -- which would hide a failed install
  local installed = {}
  for _, lang in ipairs(require('nvim-treesitter').get_installed 'parsers') do
    installed[lang] = true
  end
  for _, lang in ipairs(vim.g.ts_parsers or {}) do
    if not installed[lang] then table.insert(missing, 'parser ' .. lang) end
  end

  if vim.fn.exists ':VimQuest' ~= 2 then table.insert(missing, 'the :VimQuest command') end
  if not pcall(require, 'vimquest') then table.insert(missing, 'the vimquest module') end
  if vim.v.errmsg ~= '' then table.insert(missing, 'a clean start (error: ' .. vim.v.errmsg .. ')') end
  return missing
end

-- Any error must end Neovim too: a headless Neovim left open would hang the build
local ok, result = xpcall(check, debug.traceback)
if not ok then
  io.stderr:write('Docker check failed: ' .. result .. '\n')
  vim.cmd 'cquit 1'
elseif #result > 0 then
  io.stderr:write('Missing from the image:\n  ' .. table.concat(result, '\n  ') .. '\n')
  vim.cmd 'cquit 1'
end
vim.cmd 'qa!'
