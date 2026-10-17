-- Hyprland — environment
-- https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/

-- the GPU's variables (NVIDIA): machine/gpu.lua, from .machine.toml
require("components.machine").load("gpu")

-- GTK apps ask the portal for their file dialogs (FileChooserNative), so the shell's
-- file manager opens them: packages/xdg-portal routes FileChooser to it
hl.env("GTK_USE_PORTAL", "1")
