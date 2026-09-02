{ pkgs, ... }:

{
  wayland.windowManager.hyprland = {
    enable = true;
    configType = "lua";

    # --- 主引導檔案 (hyprland.lua) ---
    extraConfig = ''
      -- =========================================================================
      -- 2026 CYBERARCH MODULAR HYPRLAND CONFIG
      -- Inspired by Omarchy's bootstrap architecture
      -- =========================================================================

      -- 💡 這是我們的核心防爆邏輯：安全引入器
      -- 它會嘗試載入子模組，如果子模組出錯，它不會崩潰，而是發送系統通知
      local function safe_require(module_name)
          local success, err = pcall(require, module_name)
          if not success then
              hl.exec_cmd("notify-send -u critical 'Hyprland Module Error: " .. module_name .. "' '" .. tostring(err) .. "'")
          end
      end

      -- 確保緊急情況下有基礎快捷鍵保底
      hl.bind("SUPER", "Return", hl.dsp.exec_cmd("kitty"))
      hl.bind("SUPER", "M", hl.dsp.exit())

      -- 💡 將個人配置拆分為多個檔案，按順序安全載入
      -- 這些檔案會被放在 ~/.config/hypr/hypr/ 目錄下
      safe_require("hypr.monitors")
      safe_require("hypr.input")
      safe_require("hypr.looknfeel")
      safe_require("hypr.bindings")
      safe_require("hypr.autostart")
    '';
  };

  # --- 子模組生成區 ---

  # 1. 顯示器配置
  xdg.configFile."hypr/hypr/monitors.lua".text = ''
    hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })
  '';

  # 2. 輸入配置
  xdg.configFile."hypr/hypr/input.lua".text = ''
    hl.config({
        input = { kb_layout = "us", follow_mouse = 1 }
    })
  '';

  # 3. 外觀與視窗規則
  xdg.configFile."hypr/hypr/looknfeel.lua".text = ''
    hl.config({
        general = {
            gaps_in = 5, gaps_out = 20, border_size = 2, layout = "dwindle",
            col = {
                active_border = { colors = { "rgba(33ccffee)", "rgba(00ff99ee)" }, angle = 45 },
                inactive_border = "rgba(595959aa)"
            }
        },
        decoration = {
            rounding = 10,
            blur = { enabled = true, size = 3, passes = 1 }
        }
    })

    hl.window_rule({ name = "float_fcitx", match = { class = "org.fcitx.fcitx5-config-qt" }, float = true })
    hl.window_rule({ name = "float_pavu", match = { class = "pavucontrol" }, float = true })
  '';

  # 4. 快捷鍵綁定
  xdg.configFile."hypr/hypr/bindings.lua".text = ''
    local mainMod = "SUPER"
    local terminal = "kitty"
    local fileManager = "thunar"
    local menu = "fuzzel"

    hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))
    hl.bind(mainMod .. " + SHIFT + Return", hl.dsp.exec_cmd("chromium"))
    hl.bind(mainMod .. " + C", hl.dsp.window.close())
    hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
    hl.bind(mainMod .. " + D", hl.dsp.exec_cmd(menu))
    hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(menu))
    
    hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
    hl.bind(mainMod .. " + F", hl.dsp.window.float({ action = "toggle" }))
    hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.pin({ action = "toggle" }))
    
    hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("pkill -SIGUSR1 .waybar-wrapped || pkill -SIGUSR1 waybar"))
    hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd('grim -g "$(slurp)" - | wl-copy && notify-send "截圖成功" "已存入剪貼簿"'))

    for i = 1, 10 do
        local key = i % 10
        hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
        hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
    end
  '';

  # 5. 自啟動與事件
  xdg.configFile."hypr/hypr/autostart.lua".text = ''
    hl.on("hyprland.start", function()
        hl.exec_cmd("uwsm app -- waybar")
        hl.exec_cmd("uwsm app -- fcitx5 -d")
        hl.exec_cmd("uwsm app -- nm-applet --indicator")
    end)
  '';
}
