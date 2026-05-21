local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- Shell
config.default_prog = { "powershell.exe" } -- or "wsl.exe"

-- Appearance
config.color_scheme = "Poimandres"
config.font = wezterm.font("JetBrainsMono Nerd Font", { weight = "Medium" })
config.font_size = 10.8
config.line_height = 1.1
config.harfbuzz_features = { "calt=1", "clig=1", "liga=1" }

-- Window
config.window_decorations = "INTEGRATED_BUTTONS | RESIZE"
config.window_background_opacity = 0.95
config.win32_system_backdrop = "Disable"
config.window_padding = { left = 20, right = 20, top = 20, bottom = 20 }
config.initial_cols = 140
config.initial_rows = 50

-- Tab bar
config.use_fancy_tab_bar = true
config.hide_tab_bar_if_only_one_tab = false 
config.window_frame = {
	font = wezterm.font("JetBrains Mono", { weight = "Bold" }),
	font_size = 10.0,
	active_titlebar_bg = "#1B1E28",
	inactive_titlebar_bg = "#1B1E28",
}

-- Cursor
config.default_cursor_style = "BlinkingBlock"
config.cursor_blink_rate = 500
config.cursor_blink_ease_in = "EaseIn"
config.cursor_blink_ease_out = "EaseOut"

-- Key Bindings
config.leader = { key = "w", mods = "CTRL", timeout_milliseconds = 1000 }
config.keys = {
	-- Pane splits
	{ key = "p", mods = "LEADER", action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = "v", mods = "LEADER", action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }) },

	-- Navigate panes
	{ key = "h", mods = "LEADER", action = wezterm.action.ActivatePaneDirection("Left") },
	{ key = "j", mods = "LEADER", action = wezterm.action.ActivatePaneDirection("Down") },
	{ key = "k", mods = "LEADER", action = wezterm.action.ActivatePaneDirection("Up") },
	{ key = "l", mods = "LEADER", action = wezterm.action.ActivatePaneDirection("Right") },

	-- Close pane
	{ key = "x", mods = "LEADER", action = wezterm.action.CloseCurrentPane({ confirm = true }) },

	-- Close wezterm
	{ key = "q", mods = "LEADER", action = wezterm.action.QuitApplication },

	-- New tab
	{ key = "t", mods = "LEADER", action = wezterm.action.SpawnTab("CurrentPaneDomain") },

	-- Quick select (URLs, IPs, hashes)
	{ key = "f", mods = "LEADER", action = wezterm.action.QuickSelect },

	-- Switch workspace
	{ key = "w", mods = "LEADER", action = wezterm.action.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }) },
	-- New named workspace
	{
		key = "n",
		mods = "LEADER",
		action = wezterm.action.PromptInputLine({
			description = "New workspace name:",
			action = wezterm.action_callback(function(window, pane, line)
				if line then
					window:perform_action(wezterm.action.SwitchToWorkspace({ name = line }), pane)
				end
			end),
		}),
	},
}

-- Workspaces
wezterm.on("gui-startup", function(cmd)
	-- Workspace 1: Default (empty shell)
	local tab, pane, window = wezterm.mux.spawn_window({
		workspace = "Default",
	})

	-- Workspace 2: btop
	local btop_tab, btop_pane, btop_window = wezterm.mux.spawn_window({
		workspace = "btop",
	})
	btop_pane:send_text("btop4win\r\n")

	-- Workspace 3: Poerner
	local proj_tab, proj_pane, proj_window = wezterm.mux.spawn_window({
		workspace = "poerner",
		cwd = "C:/Poerner/PoernerHybrid",
	})
	
	-- Workspace 4: icm8 
	local proj_tab, proj_pane, proj_window = wezterm.mux.spawn_window({
		workspace = "icm8",
		cwd = "C:/Users/christian.kornfeld/source/repos/icm-8ui",
	})
	proj_pane:split({ direction = "Right", args = { "lazygit" } })
	
	-- Workspace 5: icm6 
	local proj_tab, proj_pane, proj_window = wezterm.mux.spawn_window({
		workspace = "icm6",
		cwd = "C:/Users/christian.kornfeld/source/repos/icm6",
	})
	proj_pane:split({ direction = "Right", args = { "lazygit" } })
	
	-- Workspace 6: icm5 
	local proj_tab, proj_pane, proj_window = wezterm.mux.spawn_window({
		workspace = "icm5",
		cwd = "C:/Users/christian.kornfeld/source/repos/icm5",
	})
	proj_pane:split({ direction = "Right", args = { "lazygit" } })

	-- Activate the Default workspace on startup
	wezterm.mux.set_active_workspace("Default")
end)

return config
