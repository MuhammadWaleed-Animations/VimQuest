-- Loaded by the Docker image before the config (see Dockerfile).
-- A container has no clipboard tool, so copies go to your real clipboard through the terminal (OSC 52) and pastes
-- return the last copy. Reading the clipboard over OSC 52 would make many terminals ask permission on every p.
local osc52 = require 'vim.ui.clipboard.osc52'

-- The last copy to each register, with its type (charwise, linewise or block), exactly as Neovim handed it over
local copied = {}

local function copy(reg)
  local send = osc52.copy(reg)
  return function(lines, regtype)
    copied[reg] = { vim.deepcopy(lines), regtype }
    send(lines)
  end
end

-- 0 means "nothing copied yet", which Neovim reports as an empty register
local function paste(reg)
  return function() return copied[reg] or 0 end
end

vim.g.clipboard = {
  name = 'OSC 52 (copy only)',
  copy = { ['+'] = copy '+', ['*'] = copy '*' },
  paste = { ['+'] = paste '+', ['*'] = paste '*' },
}
