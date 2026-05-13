local wezterm = require("wezterm")
local config = wezterm.config_builder()
local act = wezterm.action
local tabline = wezterm.plugin.require("https://github.com/michaelbrusegard/tabline.wez")
local resurrect = wezterm.plugin.require("https://github.com/MLFlexer/resurrect.wezterm")

--config.color_scheme = "tokyonight_night"
--config.color_scheme = 'Kanagawa Dragon (Gogh)'
config.color_scheme = 'Kanagawa (Gogh)'

tabline.setup({
	options = {
		theme = "Kanagawa (Gogh)",
	},
	sections = {
		tabline_b = {},
	},
})
tabline.apply_to_config(config)

resurrect.state_manager.periodic_save({ interval_seconds = 15 * 60 })
-- You can specify some parameters to influence the font selection;
-- for example, this selects a Bold, Italic font variant.
config.font = wezterm.font("0xProto Nerd Font")
-- config.font = wezterm.font("Hurmit Nerd Font")
-- config.font = wezterm.font("Monaspace Argon Light")
-- config.font = wezterm.font("FiraCode Nerd Font Mono")
--config.font = wezterm.font("SF-Mono-Nerd-Font")
config.font_size = 18.0
config.line_height = 1.2
config.inactive_pane_hsb = {
    -- hue = 0.5,
    saturation = 0.5,
    brightness = 0.5,
}

-- tab bar
--config.enable_tab_bar = false
config.hide_tab_bar_if_only_one_tab = false
config.tab_bar_at_bottom = true
config.use_fancy_tab_bar = false
--config.tab_and_split_indices_are_zero_based = true

--config.window_decorations = "RESIZE"
config.window_decorations = "RESIZE|INTEGRATED_BUTTONS"
config.window_padding = { left = "0.5cell", right = "0.5cell", top = "1cell", bottom = "0.5cell" }
--config.window_background_opacity = 0.75
--config.macos_window_background_blur = 10
wezterm.on("gui-startup", function(cmd)
	local active = wezterm.gui.screens().active
	local tab, pane, window = wezterm.mux.spawn_window(cmd or {})
	window:gui_window():set_position(active.x, active.y)
	window:gui_window():set_inner_size(active.width, active.height)

	local ok, state = pcall(resurrect.state_manager.load_state, "default", "workspace")
	if ok and state then
		resurrect.workspace_state.restore_workspace(state, {
			window = window,
			relative = true,
			restore_text = true,
			on_pane_restore = resurrect.tab_state.default_on_pane_restore,
		})
	end
end)
config.keys = {
	{ key = "LeftArrow", mods = "OPT", action = act.SendKey({ key = "b", mods = "ALT" }) },
	{ key = "RightArrow", mods = "OPT", action = act.SendKey({ key = "f", mods = "ALT" }) },
	{ key = "LeftArrow", mods = "CMD", action = act.SendKey({ key = "Home" }) },
	{ key = "RightArrow", mods = "CMD", action = act.SendKey({ key = "End" }) },
	{ key = "w", mods = "CMD|SHIFT", action = act.CloseCurrentTab({ confirm = false }) },
	{ key = "w", mods = "CMD", action = act.CloseCurrentPane({ confirm = false }) },
	{ key = "d", mods = "CMD|SHIFT", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
	{ key = "d", mods = "CMD", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = "k", mods = "CMD", action = act.ClearScrollback("ScrollbackAndViewport") },
	{ key = "p", mods = "CMD|SHIFT", action = act.ActivateCommandPalette },
	{ key = "w", mods = "CTRL|SHIFT", action = act.DisableDefaultAssignment },
	{ key = ",", mods = "CMD", action = act.SpawnCommandInNewTab({ cwd = wezterm.home_dir, args = { "vim", wezterm.config_file } }) },
	{ key = 'H', mods = 'CTRL', action = act.AdjustPaneSize { 'Left', 5 } },
  { key = 'J', mods = 'CTRL', action = act.AdjustPaneSize { 'Down', 5 } },
  { key = 'K', mods = 'CTRL', action = act.AdjustPaneSize { 'Up', 5 } },
  { key = 'L', mods = 'CTRL', action = act.AdjustPaneSize { 'Right', 5 } },
  {
    key = 'h',
    mods = 'CTRL',
    action = act.ActivatePaneDirection 'Left',
  },
  {
    key = 'l',
    mods = 'CTRL',
    action = act.ActivatePaneDirection 'Right',
  },
  {
    key = 'k',
    mods = 'CTRL',
    action = act.ActivatePaneDirection 'Up',
  },
  {
    key = 'j',
    mods = 'CTRL',
    action = act.ActivatePaneDirection 'Down',
  },
	{
    key = 'r',
    mods = 'CTRL|SHIFT',
    action = act.PromptInputLine {
      description = 'Enter new name for tab',
      action = wezterm.action_callback(function(window, pane, line)
        if line then
          window:active_tab():set_title(line)
        end
      end),
    },
  },
  {
    key = 'l',
    mods = 'CMD',
    action = act.ShowTabNavigator,
  },
  {
    key = 's',
    mods = 'CMD|SHIFT',
    action = wezterm.action_callback(function(win, pane)
      resurrect.state_manager.save_state(resurrect.workspace_state.get_workspace_state())
    end),
  },
  {
    key = 'o',
    mods = 'CMD|SHIFT',
    action = wezterm.action_callback(function(win, pane)
      resurrect.fuzzy_loader.fuzzy_load(win, pane, function(id, label)
        local type = string.match(id, "^([^/]+)")
        id = string.match(id, "([^/]+)$"):gsub("%..+$", "")
        if type == "workspace" then
          local state = resurrect.state_manager.load_state(id, "workspace")
          resurrect.workspace_state.restore_workspace(state, { relative = true, restore_text = true })
        end
      end)
    end),
  },
  {
    key = 'x',
    mods = 'CMD|SHIFT',
    action = wezterm.action_callback(function(win, pane)
      resurrect.fuzzy_loader.fuzzy_load(win, pane, function(id)
        resurrect.state_manager.delete_state(id)
      end, { title = "Delete State" })
    end),
  },
}

return config
