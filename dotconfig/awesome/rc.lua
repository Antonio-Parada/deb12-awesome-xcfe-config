-- If LuaRocks is installed, make sure that packages installed through it are
-- found (e.g. lgi). If LuaRocks is not installed, do nothing.
pcall(require, "luarocks.loader")

-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")
-- Widget and layout library
local wibox = require("wibox")
-- Theme handling library
local beautiful = require("beautiful")
-- Notification library
local naughty = require("naughty")
local menubar = require("menubar")
local hotkeys_popup = require("awful.hotkeys_popup")
require("awful.hotkeys_popup.keys")

-- Load Debian menu entries
local debian = require("debian.menu")
local has_fdo, freedesktop = pcall(require, "freedesktop")

-- {{{ Error handling
if awesome.startup_errors then
    naughty.notify({ preset = naughty.config.presets.critical,
                     title = "Oops, there were errors during startup!",
                     text = awesome.startup_errors })
end

do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        if in_error then return end
        in_error = true
        naughty.notify({ preset = naughty.config.presets.critical,
                         title = "Oops, an error happened!",
                         text = tostring(err) })
        in_error = false
    end)
end
-- }}}

-- {{{ Variable definitions
beautiful.init(gears.filesystem.get_themes_dir() .. "default/theme.lua")

terminal = "zutty"
editor = os.getenv("EDITOR") or "nano"
editor_cmd = terminal .. " -e " .. editor

modkey = "Mod4"

-- Table of layouts
awful.layout.layouts = {
    awful.layout.suit.tile,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.fair,
    awful.layout.suit.max,
    awful.layout.suit.floating,
    awful.layout.suit.magnifier,
}
-- }}}

-- {{{ Menu
myawesomemenu = {
   { "hotkeys", function() hotkeys_popup.show_help(nil, awful.screen.focused()) end },
   { "restart", awesome.restart },
   { "quit (xfce logout)", function() awful.spawn("xfce4-session-logout") end },
}

mylauncher = awful.widget.launcher({ image = beautiful.awesome_icon,
                                     menu = awful.menu({ items = { { "awesome", myawesomemenu, beautiful.awesome_icon }, { "open terminal", terminal } } }) })
-- }}}

-- {{{ Wibar
mytextclock = wibox.widget.textclock()

local taglist_buttons = gears.table.join(
                    awful.button({ }, 1, function(t) t:view_only() end),
                    awful.button({ modkey }, 1, function(t) if client.focus then client.focus:move_to_tag(t) end end),
                    awful.button({ }, 3, awful.tag.viewtoggle),
                    awful.button({ modkey }, 3, function(t) if client.focus then client.focus:toggle_tag(t) end end)
                )

local tasklist_buttons = gears.table.join(
                     awful.button({ }, 1, function (c)
                                              if c == client.focus then
                                                  c.minimized = true
                                              else
                                                  c:emit_signal("request::activate", "tasklist", {raise = true})
                                              end
                                          end))

local function set_wallpaper(s)
    if beautiful.wallpaper then
        local wallpaper = beautiful.wallpaper
        if type(wallpaper) == "function" then wallpaper = wallpaper(s) end
        gears.wallpaper.maximized(wallpaper, s, true)
    end
end

screen.connect_signal("property::geometry", set_wallpaper)

awful.screen.connect_for_each_screen(function(s)
    set_wallpaper(s)

    -- Tags: vertical (HDMI2) gets tile.bottom, horizontal (HDMI1) gets tile
    local default_layout = awful.layout.layouts[1]
    if s.geometry.height > s.geometry.width then
        default_layout = awful.layout.suit.tile.bottom
    end
    awful.tag({ "1", "2", "3", "4", "5", "6", "7", "8", "9" }, s, default_layout)

    s.mypromptbox = awful.widget.prompt()
    s.mylayoutbox = awful.widget.layoutbox(s)
    s.mylayoutbox:buttons(gears.table.join(
                           awful.button({ }, 1, function () awful.layout.inc( 1) end),
                           awful.button({ }, 3, function () awful.layout.inc(-1) end)))

    s.mytaglist = awful.widget.taglist { screen = s, filter = awful.widget.taglist.filter.all, buttons = taglist_buttons }
    s.mytasklist = awful.widget.tasklist { screen = s, filter = awful.widget.tasklist.filter.currenttags, buttons = tasklist_buttons }

    s.mywibox = awful.wibar({ position = "top", screen = s })
    s.mywibox:setup {
        layout = wibox.layout.align.horizontal,
        { layout = wibox.layout.fixed.horizontal, mylauncher, s.mytaglist, s.mypromptbox },
        s.mytasklist,
        { layout = wibox.layout.fixed.horizontal, wibox.widget.systray(), mytextclock, s.mylayoutbox },
    }
end)
-- }}}

-- {{{ Key bindings
globalkeys = gears.table.join(
    awful.key({ modkey,           }, "s",      hotkeys_popup.show_help, {description="show help", group="awesome"}),
    awful.key({ modkey,           }, "Left",   awful.tag.viewprev, {description = "view previous", group = "tag"}),
    awful.key({ modkey,           }, "Right",  awful.tag.viewnext, {description = "view next", group = "tag"}),
    awful.key({ modkey,           }, "Escape", awful.tag.history.restore, {description = "go back", group = "tag"}),

    -- Focus movement
    awful.key({ modkey,           }, "j", function () awful.client.focus.byidx( 1) end, {description = "focus next by index", group = "client"}),
    awful.key({ modkey,           }, "k", function () awful.client.focus.byidx(-1) end, {description = "focus previous by index", group = "client"}),

    -- (A) Rearranging windows
    awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end, {description = "swap with next client", group = "client"}),
    awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end, {description = "swap with previous client", group = "client"}),

    -- Screen manipulation
    awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end, {description = "focus next screen", group = "screen"}),
    awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end, {description = "focus previous screen", group = "screen"}),

    -- (B) Resizing and Layout management
    awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)          end, {description = "increase master width factor", group = "layout"}),
    awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)          end, {description = "decrease master width factor", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1, nil, true) end, {description = "increase number of master clients", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1, nil, true) end, {description = "decrease number of master clients", group = "layout"}),
    awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1, nil, true)    end, {description = "increase number of columns", group = "layout"}),
    awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1, nil, true)    end, {description = "decrease number of columns", group = "layout"}),
    awful.key({ modkey,           }, "space", function () awful.layout.inc( 1)                end, {description = "select next layout", group = "layout"}),
    awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(-1)                end, {description = "select previous layout", group = "layout"}),

    -- Standard program
    awful.key({ modkey,           }, "Return", function () awful.spawn(terminal) end, {description = "open a terminal", group = "launcher"}),
    awful.key({ modkey, "Control" }, "r", awesome.restart, {description = "reload awesome", group = "awesome"}),
    awful.key({ modkey, "Shift"   }, "q", function() awful.spawn("xfce4-session-logout") end, {description = "quit (xfce logout)", group = "awesome"}),

    -- Prompt
    awful.key({ modkey },            "r",     function () awful.screen.focused().mypromptbox:run() end, {description = "run prompt", group = "launcher"}),
    
    -- XFCE Integrated Shortcuts
    awful.key({ "Mod1" }, "F2", function() awful.spawn("xfce4-appfinder") end, {description = "run xfce-appfinder", group = "xfce"}),
    awful.key({ }, "Print", function() awful.spawn("xfce4-screenshooter") end, {description = "take screenshot", group = "xfce"}),
    awful.key({ modkey }, "b", function() for s in screen do s.mywibox.visible = not s.mywibox.visible end end, {description = "toggle wibox", group = "awesome"})
)

clientkeys = gears.table.join(
    awful.key({ modkey,           }, "f", function (c) c.fullscreen = not c.fullscreen; c:raise() end, {description = "toggle fullscreen", group = "client"}),
    awful.key({ modkey, "Shift"   }, "c", function (c) c:kill() end, {description = "close", group = "client"}),
    awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle, {description = "toggle floating", group = "client"}),
    awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end, {description = "move to master", group = "client"}),
    awful.key({ modkey,           }, "o",      function (c) c:move_to_screen() end, {description = "move window to other monitor", group = "client"}),
    awful.key({ modkey,           }, "n",      function (c) c.minimized = true end, {description = "minimize", group = "client"}),
    awful.key({ modkey,           }, "m",      function (c) c.maximized = not c.maximized; c:raise() end, {description = "(un)maximize", group = "client"})
)

-- Bind 1-9 to tags
for i = 1, 9 do
    globalkeys = gears.table.join(globalkeys,
        awful.key({ modkey }, "#" .. i + 9, function () local screen = awful.screen.focused(); local tag = screen.tags[i]; if tag then tag:view_only() end end, {description = "view tag #"..i, group = "tag"}),
        awful.key({ modkey, "Shift" }, "#" .. i + 9, function () if client.focus then local tag = client.focus.screen.tags[i]; if tag then client.focus:move_to_tag(tag) end end end, {description = "move focused client to tag #"..i, group = "tag"})
    )
end

clientbuttons = gears.table.join(
    awful.button({ }, 1, function (c) c:emit_signal("request::activate", "mouse_click", {raise = true}) end),
    awful.button({ modkey }, 1, function (c) c:emit_signal("request::activate", "mouse_click", {raise = true}); awful.mouse.client.move(c) end),
    awful.button({ modkey }, 3, function (c) c:emit_signal("request::activate", "mouse_click", {raise = true}); awful.mouse.client.resize(c) end)
)

root.keys(globalkeys)

-- Rules
awful.rules.rules = {
    -- Global Rule
    { rule = { },
      properties = { border_width = 2,
                     border_color = beautiful.border_normal,
                     focus = awful.client.focus.filter,
                     raise = true,
                     keys = clientkeys,
                     buttons = clientbuttons,
                     screen = awful.screen.preferred,
                     placement = awful.placement.no_overlap+awful.placement.no_offscreen
     }
    },
    -- Ensure Chromium tiles
    { rule = { class = "Chromium" },
      properties = { floating = false, tiling = true } },
    { rule_any = {
        class = { "xfce4-panel", "xfce4-settings-manager", "xfce4-appfinder" },
      }, properties = { floating = true }},
}

-- Signals
client.connect_signal("manage", function (c) if awesome.startup and not c.size_hints.user_position and not c.size_hints.program_position then awful.placement.no_offscreen(c) end end)
client.connect_signal("focus", function(c) c.border_color = "#3399ff" end)
client.connect_signal("unfocus", function(c) c.border_color = "#333333" end)

-- Notify on reload
naughty.notify({ title = "AwesomeWM", text = "Configuration reloaded!", timeout = 2 })

-- Autostart
awful.spawn.with_shell("xfsettingsd")
awful.spawn.with_shell("nm-applet")
