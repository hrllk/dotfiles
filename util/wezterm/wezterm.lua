local wezterm = require "wezterm"
local home = os.getenv("HOME") or "/Users/hrk"

local config = wezterm.config_builder()

config.font = wezterm.font_with_fallback({
  "JetBrains Mono",
  "Apple Color Emoji",
})
config.font_size = 12.0
config.color_scheme = "Tokyo Night"
config.line_height = 1.0
config.adjust_window_size_when_changing_font_size = false
config.window_background_image = home .. "/dotfiles/util/kitty/materials/jeremy-bishop-G9i_plbfDgk-unsplash.jpg"
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
