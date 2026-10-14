-- Hyprland — environment
-- https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/

hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("GBM_BACKEND", "nvidia-drm")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("__GL_GSYNC_ALLOWED", "1")
hl.env("__GL_VRR_ALLOWED", "1")
hl.env("__GL_SYNC_TO_VBLANK", "1")
hl.env("__GL_MaxFramesAllowed", "1")
