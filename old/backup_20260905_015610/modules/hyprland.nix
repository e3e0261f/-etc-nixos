{ pkgs, ... }:

{
  wayland.windowManager.hyprland = {
    enable = true;
    configType = "lua";

    extraConfig = ''
      -- 1. 基礎監控與變數
      hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })
      local mainMod = "SUPER"

      -- 2. 核心外觀與配置 (保持你原有的 hl.config ...)
      hl.config({
          general = { gaps_in = 5, gaps_out = 20, border_size = 2, layout = "dwindle" },
          decoration = { rounding = 10, blur = { enabled = true, size = 3, passes = 1 } }
      })

      -- 3. 快捷鍵 (保持不變)
      hl.bind(mainMod .. " + Q", hl.dsp.exec_cmd("kitty"))
      hl.bind(mainMod .. " + SHIFT + Return", hl.dsp.exec_cmd("chromium"))
      hl.bind(mainMod .. " + C", hl.dsp.window.close())
      hl.bind(mainMod .. " + M", hl.dsp.exit())
      hl.bind(mainMod .. " + F", hl.dsp.window.float({ action = "toggle" }))
      hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.pin({ action = "toggle" }))
      hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("pkill -SIGUSR1 .waybar-wrapped || pkill -SIGUSR1 waybar"))
      hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd('grim -g "$(slurp)" - | wl-copy && notify-send "截圖成功" "圖片已存入剪貼簿"'))

      -- 4. 💡 修正：直接在 Lua 中透過 os.execute 或利用 Hyprland 原生語法跑 exec-once
      -- 在 hyprland.lua 中，最穩定的自啟動方式是直接用命令列字串
    '';

    # 💡 絕招：利用 Home Manager 的原生設定來寫 exec-once
    # 這樣 Nix 會自動把它轉換成最正確的 Lua 啟動代碼，絕對不會漏掉！
    settings = {
      "exec-once" = [
        "uwsm app -- waybar"
        "uwsm app -- fcitx5 -d"
        "uwsm app -- nm-applet --indicator"
      ];
    };
  };
}
