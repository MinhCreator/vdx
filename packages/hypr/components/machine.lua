-- Hyprland — this machine's parts: machine/<name>.lua beside this config, written
-- by ./install.py from .machine.toml (`./install.py machine`). A machine without
-- one keeps the defaults of the component that asks for it.

local M = {}

-- Runs machine/<name>.lua when there is one; returns true then, nil otherwise.
-- Errors inside it are not caught: a broken file must show, not vanish.
function M.load(name)
	local module = "machine." .. name
	if package.searchpath(module, package.path) then
		require(module)
		return true
	end
end

return M
