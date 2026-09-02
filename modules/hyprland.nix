{ pkgs, ... }:

{
  wayland.windowManager.hyprland = {
    enable = true;
    configType = "lua";

    extraConfig = ''
      -- --------------------------------------------------------
      -- 2026 程序員 LUA 終極防爆版 (UWSM 兼容)
      -- --------------------------------------------------------

      -- 1. 基礎監控
      hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })

      -- 2. 基礎變數
      local terminal = "kitty"
      local fileManager = "thunar"
      local menu = "fuzzel"
      local mainMod = "SUPER"

      -- 3. 核心外觀與配置
      hl.config({
          general = {
              gaps_in = 5,
              gaps_out = 20,
              border_size = 2,
              col = {
                  active_border = { 
                      colors = { "rgba(33ccffee)", "rgba(00ff99ee)" }, 
                      angle = 45 
                  },
                  inactive_border = "rgba(595959aa)"
              },
              layout = "dwindle"
          },
          decoration = {
              rounding = 10,
              blur = { enabled = true, size = 3, passes = 1 }
          },
          input = { kb_layout = "us", follow_mouse = 1 }
      })

      -- 4. 快捷鍵
      hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd(terminal))
      hl.bind(mainMod .. " + SHIFT + Return", hl.dsp.exec_cmd("chromium"))
      hl.bind(mainMod .. " + C", hl.dsp.window.close())
      hl.bind(mainMod .. " + M", hl.dsp.exit())
      hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
      hl.bind(mainMod .. " + D", hl.dsp.exec_cmd(menu))
      hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(menu))

      hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
      hl.bind(mainMod .. " + F", hl.dsp.window.float({ action = "toggle" }))
      hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.pin({ action = "toggle" }))
      
      hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("pkill -SIGUSR1 .waybar-wrapped || pkill -SIGUSR1 waybar"))
      hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd('grim -g "$(slurp)" - | wl-copy && notify-send "截圖成功" "圖片已存入剪貼簿"'))

      -- 工作區導航
      for i = 1, 10 do
          local key = i % 10
          hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
          hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
      end

      -- 5. 絕對安全的啟動項 (純淨的 uwsm app 委託，不碰 systemctl)
      hl.on("hyprland.start", function()
          hl.exec_cmd("uwsm app -- waybar")
          hl.exec_cmd("uwsm app -- fcitx5 -d")
          hl.exec_cmd("uwsm app -- nm-applet --indicator")
      end)

      -- 6. 視窗規則
      hl.window_rule({
          name = "float",
          match = { class = "org.fcitx.fcitx5-config-qt" },
          float = true
      })
    '';
  };
}
