{ pkgs, ... }:

{
  wayland.windowManager.hyprland = {
    enable = true;
    configType = "lua";

    # 1. 核心引導橋樑
    extraConfig = ''
      local home = os.getenv("HOME")
      package.path = home .. "/.config/MYHYprLUa/?.lua;" .. package.path
      
      local function safe_load(m) 
        local ok, err = pcall(require, m) 
        if not ok then hl.exec_cmd("notify-send 'Error' 'Fail to load "..m.."'") end 
      end

      safe_load("default")
    '';
  };

  # 2. default.lua 入口
  xdg.configFile."MYHYprLUa/default.lua".text = ''
    require("window_rules")
    require("bindings")
    require("MONITORS")
    require("AUTOSTART")
    require("ENVIRONMENT")
    require("LOOKANDFEEL")
    require("MISC")
    require("INPUT")
    require("WINDOWSANDWORKSPACES")
  '';

  # =======================================================
  # 1. 視窗規則模組 (精準排版與置中懸浮)
  # =======================================================
  xdg.configFile."MYHYprLUa/window_rules.lua".text = ''
    hl.window_rule({ name = "float_fcitx", match = { class = "org.fcitx." }, float = true })
    hl.window_rule({ name = "vlc", match = { class = "vlc" }, float = true })
    hl.window_rule({ name = "vscodium", match = { class = "vscodium" }, float = true})
    hl.window_rule({ name = "spotify", match = { class = "spotify" }, float = true })
    hl.window_rule({ name = "nemo", match = { class = "nemo" }, float = true })
    hl.window_rule({ name = "steam", match = { class = "steam" }, float = true })
    hl.window_rule({ name = "org.qbittorrent", match = { class = "org.qbittorrent" }, float = true })
    hl.window_rule({ name = "float_pavu", match = { class = "pavucontrol" }, float = true })
    hl.window_rule({ name = "float_dolphin", match = { class = "org.kde.dolphin" }, float = true })
    hl.window_rule({ name = "float_yad", match = { class = "yad" }, float = true, center = "1" })
    hl.window_rule({ name = "center_float", match = { float = true }, center = true })

    -- ⭐️ 1. Chromium 鎖定 Workspace 1
    hl.window_rule({ name = "chromium_ws1", match = { class = "chromium" }, workspace = "1" })
    hl.window_rule({ name = "chromium_browser_ws1", match = { class = "chromium-browser" }, workspace = "1" })

    -- ⭐️ 1. google-chrome 鎖定 Workspace 1
    hl.window_rule({ name = "google-chrome_ws1", match = { class = "google-chrome" }, workspace = "1" })
    hl.window_rule({ name = "google-chrome_browser_ws1", match = { class = "google-chrome-browser" }, workspace = "1" })

    -- ⭐️ 2. Kitty 專屬右側半屏懸浮
    hl.window_rule({ name = "kitty", match = { class = "kitty" }, float = true, size = "50% 100%", move = "50% 0" })

    -- ⭐️ 3. Workspace 4：音訊雙雄對開 (靜默不搶視角)
    hl.window_rule({ name = "qpwgraph_ws4_left", match = { class = "org.rncbc.qpwgraph" }, workspace = "4 silent", size = "50% 100%", move = "0 0" })
    hl.window_rule({ name = "easyeffects_ws4_right", match = { class = "com.github.wwmm.easyeffects" }, workspace = "4 silent", size = "50% 100%", move = "50% 0" })

    -- Discord 鎖定 Workspace 3
    hl.window_rule({ name = "discord", match = { class = "discord" }, workspace = "3 silent" })

    -- ⭐️ 4. Yazi 檔案管理器：75% 置中優雅懸浮
    hl.window_rule({
      name = "yazi_float_center",
      match = { class = "yazi-float" },
      float = true,
      center = true,
      size = "75% 75%",
    })
  '';

  # =======================================================
  # 2. 快捷鍵模組
  # =======================================================
  xdg.configFile."MYHYprLUa/bindings.lua".text = ''
    local terminal    = "kitty"
    -- ⭐️ 改為呼叫專屬 class，按 Super+E 時精準觸發 75% 置中懸浮 Yazi！
    local fileManager = "nemo"
    local menu        = "fuzzel"
    local mainMod     = "SUPER"
    
    -- =======================================================
    -- ⭐️ 官方原生：Alt + Tab 切換視窗並置頂層級 (誰在前誰在後)
    -- =======================================================

    -- 1. Alt + Tab：順向切換視窗，並將該視窗翻到最頂層
    hl.bind("ALT + Tab", function()
      hl.dispatch(hl.dsp.window.cycle_next())
      hl.dispatch(hl.dsp.window.bring_to_top())
    end)

    -- 2. Alt + Shift + Tab：反向切換視窗，並將該視窗翻到最頂層
    hl.bind("ALT + SHIFT + Tab", function()
      hl.dispatch(hl.dsp.window.cycle_next({ next = false }))
      hl.dispatch(hl.dsp.window.bring_to_top())
    end)

    

    -- ⭐️ 2. Ctrl + Super + W：隨機抽取一張 2K 高畫質桌布（8大轉場特效全隨機！）
    hl.bind(mainMod .. " + CTRL + R", hl.dsp.exec_cmd("wall-random"))
    -- ⭐️ 2. Ctrl + Super + W：隨機抽取一張 2K 高畫質桌布（8大轉場特效全隨機！）
    hl.bind(mainMod .. " + CTRL + W", hl.dsp.exec_cmd("wall-video"))

    -- 錄影快捷鍵
    hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("record-screen area"))
    hl.bind(mainMod .. " + CTRL + SHIFT + R", hl.dsp.exec_cmd("record-screen fullscreen"))

    -- 基礎操作
    hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))
    hl.bind(mainMod .. " + C", hl.dsp.window.close())
    hl.bind(mainMod .. " + SHIFT + DELETE", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))
    hl.bind(mainMod .. " + SHIFT + CTRL + ALT + DELETE", hl.dsp.exec_cmd("hyprctl reload"))
    
    hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
    hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
    hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(menu))
    hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
    hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))

    hl.bind(mainMod .. " + F", hl.dsp.window.float({ action = "toggle" }))
    hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.pin({ action = "toggle" }))
    hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("pkill -SIGUSR1 .waybar-wrapped || pkill -SIGUSR1 waybar"))
    hl.bind(mainMod .. " + SHIFT + CTRL + S", hl.dsp.exec_cmd("trans-gui"))

    -- 方向導航
    hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
    hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
    hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
    hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

    -- =======================================================
    -- ⭐️ 專業截圖矩陣（截選單、全螢幕、區域拉框全搞定）
    -- =======================================================

    -- 1. ⭐️ 區域定格截圖（真正的一鍵定格拉框，絕不誤解凍）：Super + Ctrl + S
    hl.bind(mainMod .. " + CTRL + S", hl.dsp.exec_cmd("hyprshot -m region --freeze -o ~/Pictures/Screenshots"))

    -- 2. 全螢幕定格秒截：Super + Print
    hl.bind(mainMod .. " + Print", hl.dsp.exec_cmd("hyprshot -m output --freeze -o ~/Pictures/Screenshots"))

    -- 3. 當前單一視窗截圖（可選）：Super + Alt + S
    hl.bind(mainMod .. " + ALT + S", hl.dsp.exec_cmd("hyprshot -m window --freeze -o ~/Pictures/Screenshots"))

    -- 工作區切換
    for i = 1, 10 do
        local key = i % 10
        hl.bind(mainMod .. " + " .. key,             hl.dsp.focus({ workspace = i }))
        hl.bind(mainMod .. " + SHIFT + " .. key,     hl.dsp.window.move({ workspace = i }))
    end

    -- 暫存空間 Magic
    hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))
    hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

    -- 滾輪切換工作區
    hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
    hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

    -- 滑鼠拖曳與縮放
    hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
    hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

    -- 筆電多媒體鍵
    hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
    hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
    hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
    hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
    hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
    hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })

    hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
    hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
    hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
    hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })
  '';

  xdg.configFile."MYHYprLUa/MONITORS.lua".text = '''';

  # =======================================================
  # 5. 自啟動模組 (開機視角牢牢鎖定 Workspace 1)
  # =======================================================
  xdg.configFile."MYHYprLUa/AUTOSTART.lua".text = ''
    hl.on("hyprland.start", function ()
      hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP HYPRLAND_INSTANCE_SIGNATURE")
      hl.exec_cmd("fcitx5 -d")
      hl.exec_cmd("nm-applet --indicator")
      hl.exec_cmd("google-chrome")
      hl.exec_cmd("qpwgraph")
      hl.exec_cmd("easyeffects --gapplication-service")
      hl.exec_cmd("discord")
      
      -- ⭐️ 核心保險：等背景程式就位後，把視角強制拉回 1 號工作區！
      hl.exec_cmd("sleep 0.5 && hyprctl dispatch workspace 1")
    end)
  '';

  xdg.configFile."MYHYprLUa/ENVIRONMENT.lua".text = ''
    hl.env("XCURSOR_SIZE", "24")
    hl.env("HYPRCURSOR_SIZE", "24")
  '';

  # =======================================================
  # 7. 外觀與高質感調光模組 (LOOKANDFEEL.lua)
  #    ⭐️ 徹底刪除重複定義，解除暗淡，開啟高級質感
  # =======================================================
  xdg.configFile."MYHYprLUa/LOOKANDFEEL.lua".text = ''
    -- 為 Waybar 啟用硬體加速雙重毛玻璃
    hl.layer_rule({ name = "waybar-blur", match = { namespace = "waybar" }, blur = true })
    hl.layer_rule({ name = "waybar-alpha", match = { namespace = "waybar" }, ignore_alpha = 0.2 })

    hl.config({
        cursor = {
        no_hardware_cursors = false,    -- ⭐️ 強制開啟顯卡硬體游標
        use_cpu_buffer = false,         -- ⭐️ 嚴禁使用 CPU 記憶體畫滑鼠！由 GPU 顯存直接輸出
        no_break_fs_vrr = true,
        min_refresh_rate = 60,          -- 最低鎖定 60 幀
        },
        general = {
            gaps_in  = 5,
            gaps_out = 16,
            border_size = 2,

            col = {
                -- ⭐️ 當前視窗：賽博青藍到極光紫的流光邊框
                active_border   = { colors = {"rgba(33ccffee)", "rgba(bd93f9ee)"}, angle = 45 },
                -- ⭐️ 非當前視窗：深邃黑曜石邊框，低調優雅
                inactive_border = "rgba(1e1e2eaa)",
            },

            resize_on_border = false,
            -- ⭐️ 開啟極致響應（允許遊戲或全螢幕無延遲直通，消除微幅卡頓）
            allow_tearing = true,
            layout = "dwindle",
        },

        decoration = {
            rounding       = 12,
            rounding_power = 2,

            -- ⭐️ 核心解鎖 1：視窗 100% 清澈透亮，非當前視窗絕不變透明！
            active_opacity   = 1.0,
            inactive_opacity = 1.0,

            -- ⭐️ 核心解鎖 2：徹底幹掉暗淡，背景視窗永遠保持原汁原味亮度！
            dim_inactive = false,
            dim_strength = 0.0,

            -- ⭐️ 高級漫射環境光陰影
            shadow = {
                enabled      = true,
                range        = 18,
                render_power = 3,
                color        = 0x44000000,
            },

            -- ⭐️ 3 遍極致深邃的 Kawase 磨砂毛玻璃
            blur = {
                enabled   = true,
                size      = 6,
                passes    = 3,
                new_optimizations = true,
                ignore_opacity    = true,
                vibrancy          = 0.2,
            },
        },

        animations = {
            enabled = true,
        },
    })

    -- 絲滑貝茲曲線
    hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1}    } })
    hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1}    } })
    hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}       } })
    hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1}    } })
    hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}     } })
    hl.curve("easy",           { type = "spring", mass = 1, stiffness = 238.1191, dampening = 24.21279333 })

    hl.animation({ leaf = "global",        enabled = true,  speed = 10,   bezier = "default" })
    hl.animation({ leaf = "border",        enabled = true,  speed = 5.39, bezier = "easeOutQuint" })
    hl.animation({ leaf = "windows",       enabled = true,  speed = 4.79, spring = "easy" })
    hl.animation({ leaf = "windowsIn",     enabled = true,  speed = 4.1,  spring = "easy",         style = "popin 87%" })
    hl.animation({ leaf = "windowsOut",    enabled = true,  speed = 1.49, bezier = "linear",       style = "popin 87%" })
    hl.animation({ leaf = "fadeIn",        enabled = true,  speed = 1.73, bezier = "almostLinear" })
    hl.animation({ leaf = "fadeOut",       enabled = true,  speed = 1.46, bezier = "almostLinear" })
    hl.animation({ leaf = "fade",          enabled = true,  speed = 3.03, bezier = "quick" })
    hl.animation({ leaf = "layers",        enabled = true,  speed = 3.81, bezier = "easeOutQuint" })
    hl.animation({ leaf = "layersIn",      enabled = true,  speed = 4,    bezier = "easeOutQuint", style = "fade" })
    hl.animation({ leaf = "layersOut",     enabled = true,  speed = 1.5,  bezier = "linear",       style = "fade" })
    hl.animation({ leaf = "fadeLayersIn",  enabled = true,  speed = 1.79, bezier = "almostLinear" })
    hl.animation({ leaf = "fadeLayersOut", enabled = true,  speed = 1.39, bezier = "almostLinear" })
    hl.animation({ leaf = "workspaces",    enabled = true,  speed = 1.94, bezier = "almostLinear", style = "fade" })
    hl.animation({ leaf = "workspacesIn",  enabled = true,  speed = 1.21, bezier = "almostLinear", style = "fade" })
    hl.animation({ leaf = "workspacesOut", enabled = true,  speed = 1.94, bezier = "almostLinear", style = "fade" })
    hl.animation({ leaf = "zoomFactor",    enabled = true,  speed = 7,    bezier = "quick" })

    hl.config({
        dwindle = {
            preserve_split = true,
        },
        master = {
            new_status = "master",
        },
        scrolling = {
            fullscreen_on_one_column = true,
        },
    })
  '';

  xdg.configFile."MYHYprLUa/MISC.lua".text = ''
    hl.config({
      misc = {
        force_default_wallpaper = 0,
        disable_hyprland_logo   = true,
        focus_on_activate       = false, -- ⭐️ 禁止軟體在後台啟動時搶奪焦點
      },
    })
  '';

  xdg.configFile."MYHYprLUa/INPUT.lua".text = ''
    hl.config({
      input = {
        accel_profile = "flat", -- 絕對直線，無軟體加速
        kb_layout  = "us",
        follow_mouse = 1,
        sensitivity = 0,
        touchpad = { natural_scroll = false },
      },
    })

    hl.gesture({
      fingers = 3,
      direction = "horizontal",
      action = "workspace"
    })
  '';

  xdg.configFile."MYHYprLUa/WINDOWSANDWORKSPACES.lua".text = ''
    hl.window_rule({
      name  = "suppress-maximize-events",
      match = { class = ".*" },
      suppress_event = "maximize",
    })

    hl.window_rule({
      name  = "fix-xwayland-drags",
      match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
      },
      no_focus = true,
    })
  '';     
}
