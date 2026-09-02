{ pkgs, config, ... }:

{
  wayland.windowManager.hyprland = {
    enable = true;
    configType = "lua";

    # 1. 這裡放最基礎、絕對不能崩潰的核心設定
    settings = {
      monitor = [ ",preferred,auto,1" ];
      "$mainMod" = "SUPER";
    };

    # 2. 注入 pcall 載入外部的「客製化檔案」
    extraConfig = ''
      ---------------------------------------------------------
      -- 2026 程序員安全載入邏輯
      ---------------------------------------------------------
      -- 定義檔案路徑 (不搶 hyprland.lua 的名字)
      local custom_config_path = os.getenv("HOME") .. "/.config/hypr/custom_settings.lua"

      local success, err = pcall(dofile, custom_config_path)

      if not success then
          -- 如果載入失敗，彈出通知並提供救命終端
          hl.exec_cmd("notify-send -u critical 'Hyprland Custom Config Error' '" .. tostring(err) .. "'")
          
          -- 保底快捷鍵：確保你進得去修檔案
          hl.bind("SUPER, Return", hl.dsp.exec_cmd("kitty"))
          hl.bind("SUPER, Q", hl.dsp.exec_cmd("kitty"))
          hl.bind("SUPER SHIFT, M", "exit,")
      end
    '';
  };

  # 3. 💡 這是重點：我們在 Nix 裡定義這個「外部檔案」
  # 這樣它就不叫 hyprland.lua，Nix 不會跟你吵架
  xdg.configFile."hypr/custom_settings.lua".text = ''
    -- 這裡放你原本所有的快捷鍵、啟動項等高風險配置
    
    -- 啟動項
    hl.on("hyprland.ready", function()
        hl.exec_cmd("uwsm app -- waybar")
        hl.exec_cmd("uwsm app -- fcitx5 -d")
        hl.exec_cmd("uwsm app -- nm-applet --indicator")
    end)

    -- 你的主力快捷鍵
    hl.bind("SUPER, Q", hl.dsp.exec_cmd("kitty"))
    hl.bind("SUPER SHIFT, Return", hl.dsp.exec_cmd("chromium"))
    hl.bind("SUPER, D", hl.dsp.exec_cmd("fuzzel"))
    hl.bind("SUPER, F", "togglefloating,")
    hl.bind("SUPER SHIFT, F", "pin,")
    
    -- 你的 Waybar 開關魔法
    hl.bind("SUPER, W", hl.dsp.exec_cmd("pkill -SIGUSR1 .waybar-wrapped || pkill -SIGUSR1 waybar"))

    -- 視窗規則
    hl.config({
        windowrulev2 = {
            "float, class:(org.fcitx.fcitx5-config-qt)",
            "float, class:(pavucontrol)"
        }
    })
  '';
}
