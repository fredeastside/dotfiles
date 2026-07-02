local wezterm = require("wezterm")
local config = wezterm.config_builder()
local act = wezterm.action
local tabline = wezterm.plugin.require("https://github.com/michaelbrusegard/tabline.wez")
local resurrect = wezterm.plugin.require("https://github.com/MLFlexer/resurrect.wezterm")
local smart_splits = wezterm.plugin.require("https://github.com/mrjones2014/smart-splits.nvim")

-- Store resurrect state outside the plugin folder so plugin auto-updates can't
-- wipe saved sessions. The workspace/window/tab subdirs must already exist.
resurrect.state_manager.change_state_save_dir(wezterm.home_dir .. "/.local/share/wezterm/resurrect/")

--config.color_scheme = "tokyonight_night"
--config.color_scheme = 'Kanagawa Dragon (Gogh)'
config.color_scheme = 'Kanagawa (Gogh)'

local function tab_label(_, tab)
	if tab.tab_title and #tab.tab_title > 0 then
		return tab.tab_title
	end
	local pane = tab.active_pane
	local cwd = pane and pane.current_working_dir
	if cwd then
		local path = (cwd.file_path or tostring(cwd)):gsub("/$", "")
		local parent, current = path:match("([^/]+)/([^/]+)$")
		if parent and current then
			return parent .. "/" .. current
		end
		return path:match("([^/]+)$") or path
	end
	local proc = pane and pane.foreground_process_name or ""
	return proc:match("([^/\\]+)$") or "default"
end

tabline.setup({
	options = {
		theme = "Kanagawa (Gogh)",
	},
	sections = {
		tabline_b = {},
		tab_active = { "index", { "process", fmt = tab_label, padding = { left = 0, right = 1 } } },
		tab_inactive = { "index", { "process", fmt = tab_label, padding = { left = 0, right = 1 } } },
	},
})
tabline.apply_to_config(config)

-- NOTE: resurrect's periodic_save (wezterm.time.call_after) does not reliably
-- fire when scheduled from config top-level, so nothing ever got saved. Instead
-- drive saves off update-status (fires ~every 1s regardless of focus), throttled
-- to every 2 minutes via os.time().
local resurrect_last_save = 0
wezterm.on("update-status", function(window, pane)
	local now = os.time()
	if now - resurrect_last_save < 120 then
		return
	end
	resurrect_last_save = now
	local ok, state = pcall(resurrect.workspace_state.get_workspace_state)
	if ok and state then
		resurrect.state_manager.save_state(state)
	end
end)
-- You can specify some parameters to influence the font selection;
-- for example, this selects a Bold, Italic font variant.
config.font = wezterm.font("0xProto Nerd Font", {
	-- harfbuzz_features = { "calt=0", "clig=0", "liga=0" }, -- uncomment to disable ligatures
})
-- config.font = wezterm.font("Hurmit Nerd Font")
-- config.font = wezterm.font("Monaspace Argon Light")
-- config.font = wezterm.font("FiraCode Nerd Font Mono")
--config.font = wezterm.font("SF-Mono-Nerd-Font")
config.font_size = 19.0
config.line_height = 1.2

config.front_end = "WebGpu"
config.scrollback_lines = 10000
config.audible_bell = "Disabled"
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
	{ key = ",", mods = "CMD", action = act.SpawnCommandInNewTab({ cwd = wezterm.home_dir, args = { "vim", wezterm.config_file } }) },
	-- NOTE: CTRL+hjkl (move) and META+hjkl (resize) are registered by
	-- smart_splits.apply_to_config below; they hand off to Neovim splits when nvim is focused.
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
    -- Fuzzy-search open tabs by title, then jump to the match.
    key = 'l',
    mods = 'CMD',
    action = wezterm.action_callback(function(window, pane)
      local tabs = window:mux_window():tabs()
      local choices = {}
      for i, tab in ipairs(tabs) do
        local title = tab:get_title()
        if not title or #title == 0 then
          title = tab:active_pane():get_title()
        end
        table.insert(choices, {
          id = tostring(i), -- 1-based index into `tabs`
          label = string.format('%d: %s', i, title),
        })
      end
      window:perform_action(
        act.InputSelector({
          title = 'Search tabs',
          fuzzy = true,
          choices = choices,
          -- Activate the mux tab object directly. Performing ActivateTab here
          -- races with the InputSelector overlay teardown (which refocuses the
          -- original tab), so the selection would not stick.
          action = wezterm.action_callback(function(win, p, id)
            if id then
              tabs[tonumber(id)]:activate()
            end
          end),
        }),
        pane
      )
    end),
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

-- smart-splits: CTRL+hjkl to move between Neovim splits AND WezTerm panes,
-- META(Option)+hjkl to resize. Routes the key into Neovim when it's the
-- focused process (detected via the IS_NVIM user var), otherwise acts on panes.
smart_splits.apply_to_config(config, {
	modifiers = {
		move = "CTRL",
		resize = "META",
	},
})

return config
