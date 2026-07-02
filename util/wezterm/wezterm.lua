local wezterm = require "wezterm"
local home = os.getenv("HOME") or "/Users/hrk"

local config = wezterm.config_builder()
local kitty_active_border = "#2DD4BF"
local kitty_inactive_border = "#3b4261"

local active_window_frame = {
  border_left_width = "0.25cell",
  border_right_width = "0.25cell",
  border_top_height = "0.125cell",
  border_bottom_height = "0.125cell",
  border_left_color = kitty_active_border,
  border_right_color = kitty_active_border,
  border_top_color = kitty_active_border,
  border_bottom_color = kitty_active_border,
}

local inactive_window_frame = {
  border_left_width = "0.25cell",
  border_right_width = "0.25cell",
  border_top_height = "0.125cell",
  border_bottom_height = "0.125cell",
  border_left_color = kitty_inactive_border,
  border_right_color = kitty_inactive_border,
  border_top_color = kitty_inactive_border,
  border_bottom_color = kitty_inactive_border,
}

local function apply_window_frame(window)
  local frame = window:is_focused() and active_window_frame or inactive_window_frame
  window:set_config_overrides({
    window_frame = frame,
  })
end

wezterm.on("window-focus-changed", function(window, pane)
  apply_window_frame(window)
end)

wezterm.on("window-config-reloaded", function(window)
  apply_window_frame(window)
end)

config.font = wezterm.font_with_fallback({
  "JetBrains Mono",
  "Apple Color Emoji",
})
config.font_size = 12.0
config.color_scheme = "Tokyo Night"
config.line_height = 0.9
config.adjust_window_size_when_changing_font_size = false
config.background = {
  {
    source = {
      File = home .. "/dotfiles/util/assets/wallpapers/jeremy-bishop-G9i_plbfDgk-unsplash.jpg",
    },
    hsb = {
      brightness = 0.75,
    },
  },
  {
    source = {
      Color = "black",
    },
    opacity = 0.22,
    width = "100%",
    height = "100%",
  },
}
config.window_background_opacity = 1.0
config.macos_window_background_blur = 0

config.window_padding = {
  left = 10,
  right = 10,
  top = 8,
  bottom = 8,
}

config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true
config.tab_bar_at_bottom = true
config.window_decorations = "RESIZE"
config.window_frame = active_window_frame

config.audible_bell = "Disabled"
config.warn_about_missing_glyphs = false
config.enable_scroll_bar = false
config.window_close_confirmation = "NeverPrompt"

config.keys = {
  {
    key = "Enter",
    mods = "ALT",
    action = wezterm.action.DisableDefaultAssignment,
  },
  {
    key = "L",
    mods = "CMD|SHIFT",
    action = wezterm.action.ShowLauncherArgs {
      flags = "FUZZY|TABS|LAUNCH_MENU_ITEMS",
    },
  },
  {
    key = "R",
    mods = "CMD|SHIFT",
    action = wezterm.action.ReloadConfiguration,
  },
  {
    key = "f",
    mods = "CMD|CTRL",
    action = wezterm.action.ToggleFullScreen,
  },
  {
    key = "F",
    mods = "CMD|CTRL",
    action = wezterm.action.ToggleFullScreen,
  },
  {
    key = "Enter",
    mods = "SUPER",
    action = wezterm.action.ToggleFullScreen,
  },
  {
    key = "W",
    mods = "CMD",
    action = wezterm.action.CloseCurrentTab { confirm = false },
  },
}

return config
