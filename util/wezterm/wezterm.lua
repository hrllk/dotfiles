local wezterm = require "wezterm"
local home = os.getenv("HOME") or "/Users/hrk"

local config = wezterm.config_builder()
-- Sonokai "andromeda" palette, copied verbatim from the colorscheme nvim runs
-- (sonokai/autoload/sonokai.vim). Keeping the literals identical is the point:
-- editor, multiplexer and terminal chrome all read from the same six values, so
-- the only colour that varies across a split is the code itself.
local sonokai = {
  black = "#181A1C",
  fg = "#E1E3E4",
  grey = "#7E8294",
  grey_dim = "#5A5E7A",
  bg3 = "#393E53",
  red = "#FB617E",
  orange = "#F89860",
  yellow = "#EDC763",
  green = "#9ED06C",
  blue = "#6DCAE8",
  purple = "#BB97EE",
}

-- Orange is the single chrome accent, and the frame now wears it unconditionally.
--
-- This used to recolour on focus, through a window-focus-changed handler that
-- called set_config_overrides. WezTerm has no API for the window frame short of
-- a config override, and an override re-evaluates this file and reconfigures the
-- window on the GUI thread -- so every Cmd+` switched the window instantly and
-- then swallowed keystrokes for a beat while two windows rebuilt themselves.
-- Which window has focus is now shown by the tmux status line instead (see the
-- client-focus hooks in util/tmux/.tmux.conf); redrawing a status line costs
-- nothing next to reconfiguring a 6720x3780 window.
local window_frame = {
  border_left_width = "0.25cell",
  border_right_width = "0.25cell",
  border_top_height = "0.125cell",
  border_bottom_height = "0.125cell",
  border_left_color = sonokai.orange,
  border_right_color = sonokai.orange,
  border_top_color = sonokai.orange,
  border_bottom_color = sonokai.orange,
}

config.font = wezterm.font_with_fallback({
  { family = "JetBrains Mono", weight = "Medium" },
  { family = "Apple SD Gothic Neo", weight = "DemiBold" },
  "Apple Color Emoji",
})
config.font_size = 12

-- Stated rather than left to the default, which varies by build, and this build
-- reports no version at all. WebGpu goes through Metal here; the power
-- preference matters on machines with a discrete GPU and is harmless on this
-- one. max_fps is raised past the default 60 for the 120Hz internal panel --
-- the 60Hz external display simply will not use the headroom.
config.front_end = "WebGpu"
config.webgpu_power_preference = "HighPerformance"
config.max_fps = 120
-- Defined inline rather than picked from wezterm's bundled schemes so the ANSI
-- table matches sonokai exactly. Note slot 6: sonokai maps cyan to orange, and
-- following it keeps `ls`/`git` output in the same two-colour world as the
-- chrome. Swap in sonokai.blue there to get a conventional cyan back.
config.color_schemes = {
  ["Sonokai Andromeda"] = {
    foreground = sonokai.fg,
    background = "#000000",
    cursor_bg = sonokai.orange,
    cursor_fg = "#000000",
    cursor_border = sonokai.orange,
    selection_bg = sonokai.bg3,
    selection_fg = sonokai.fg,
    ansi = {
      sonokai.black,
      sonokai.red,
      sonokai.green,
      sonokai.yellow,
      sonokai.blue,
      sonokai.purple,
      sonokai.orange,
      sonokai.fg,
    },
    brights = {
      sonokai.grey,
      sonokai.red,
      sonokai.green,
      sonokai.yellow,
      sonokai.blue,
      sonokai.purple,
      sonokai.orange,
      sonokai.fg,
    },
    tab_bar = {
      background = "#000000",
      active_tab = { bg_color = "#000000", fg_color = sonokai.orange, intensity = "Bold" },
      inactive_tab = { bg_color = "#000000", fg_color = sonokai.grey },
      inactive_tab_hover = { bg_color = "#000000", fg_color = sonokai.fg },
      new_tab = { bg_color = "#000000", fg_color = sonokai.grey_dim },
      new_tab_hover = { bg_color = "#000000", fg_color = sonokai.fg },
    },
  },
}
config.color_scheme = "Sonokai Andromeda"
config.line_height = 0.9
config.adjust_window_size_when_changing_font_size = false
config.background = {
  {
    source = {
      -- File = home .. "/dotfiles/util/assets/wallpapers/pexels-agnieszka-taggart-3157904-39281575.jpg",
      -- File = home .. "/dotfiles/util/assets/wallpapers/pexels-thales13-39007224.jpg",
      -- File = home .. "/dotfiles/util/assets/wallpapers/pexels-thales13-39069329.jpg",
      --

    -- File = home .. "/dotfiles/util/assets/wallpapers/pexels-lucasandrade-11755269.jpg",
    -- File = home .. "/dotfiles/util/assets/wallpapers/pexels-nadunvishwanath-33820512.jpg",
    -- File = home .. "/dotfiles/util/assets/wallpapers/pexels-hvitkerist-38999718.jpg",
    -- File = home .. "/dotfiles/util/assets/wallpapers/pexels-vladimirsrajber-39022915.jpg",
    -- File = home .. "/dotfiles/util/assets/wallpapers/pexels-rperucho-39052377.jpg",
    
    
      -- File = home .. "/dotfiles/util/assets/wallpapers/pexels-hvitkerist-38999721.jpg",
      -- File = home .. "/dotfiles/util/assets/wallpapers/jeremy-bishop-G9i_plbfDgk-unsplash.jpg",
      -- File = home .. "/dotfiles/util/assets/wallpapers/pexels-nejc-soklic-7862643-6521543.jpg",
      -- File = home .. "/dotfiles/util/assets/wallpapers/pexels-arts-1214011.jpg",
      --
      -- File = home .. "/dotfiles/util/assets/wallpapers/pexels-marek-piwnicki-3907296-8387393.jpg",
      -- File = home .. "/dotfiles/util/assets/wallpapers/pexels-marek-piwnicki-3907296-9606971.jpg",
      -- File = home .. "/dotfiles/util/assets/wallpapers/pexels-marek-piwnicki-3907296-11032454.jpg",
      -- File = home .. "/dotfiles/util/assets/wallpapers/pexels-thales13-38875180.jpg",
      File = home .. "/dotfiles/util/assets/wallpapers/pexels-tima-miroshnichenko-7033937.jpg",


    },
    hsb = {
      brightness = 0.95,
    },
  },
  {
    source = {
      Color = "black",
    },
    -- 0.85 reduces the wallpaper to texture rather than imagery, which is what
    -- lets the orange chrome read as the brightest thing on screen. Lower it
    -- back toward 0.30 to bring the photo forward again.
    opacity = 0.55,
    -- opacity = 0,
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
config.window_frame = window_frame

config.audible_bell = "Disabled"
config.warn_about_missing_glyphs = false
config.enable_scroll_bar = false
config.window_close_confirmation = "NeverPrompt"

config.keys = {
  -- Cmd+` cannot be bound here: macOS claims it as a system shortcut ("move
  -- focus to the next window") and the key never reaches wezterm at all --
  -- verified by binding a callback to it and watching it never fire, while the
  -- same callback on Cmd+Shift+Y fired every time. Opt+` is the same physical
  -- key on a path wezterm can actually see, so the switch stays in-process.
  {
    key = "`",
    mods = "ALT",
    action = wezterm.action.ActivateWindowRelative(1),
  },
  {
    key = "`",
    mods = "ALT|SHIFT",
    action = wezterm.action.ActivateWindowRelative(-1),
  },
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
