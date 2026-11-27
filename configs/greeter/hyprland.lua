-- The compositor behind the login screen, and nothing else: no keybinds, and
-- it leaves as soon as the greeter does, however the greeter ended.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

-- The layout the password was chosen with.
local layout, variant = "us", ""
local keyboard = io.open("/etc/default/keyboard")
if keyboard then
    for line in keyboard:lines() do
        local key, value = line:match('^(XKB%u+)="?([%w_,%-]*)"?$')
        if key == "XKBLAYOUT" and value ~= "" then layout = value end
        if key == "XKBVARIANT" then variant = value end
    end
    keyboard:close()
end

hl.config({
    input = { kb_layout = layout, kb_variant = variant, accel_profile = "flat", touchpad = { tap_to_click = true } },
    animations = { enabled = false },
    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        key_press_enables_dpms = true,
        mouse_move_enables_dpms = true,
    },
    ecosystem = { no_update_news = true, no_donation_nag = true },
})

hl.on("hyprland.start", function()
    hl.exec_cmd("qs -p /etc/xdg/quickshell/triton/greeter.qml >\"$HOME/greeter.log\" 2>&1; hyprctl dispatch 'hl.dsp.exit()'")
end)
