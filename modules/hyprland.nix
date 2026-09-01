
{ pkgs, ... }:

{
  wayland.windowManager.hyprland = {
    enable = true;
    configType = "hyprlang"; # 消除之前的 Lua 警告
    
    settings = {
      "$mainMod" = "SUPER";

      # --- 快捷鍵 ---
      bind = [
        "$mainMod, F, togglefloating,"
        "$mainMod SHIFT, F, pin,"
        # 修復後的 Waybar Toggle 魔法
        "$mainMod, W, exec, pkill -SIGUSR1 .waybar-wrapped || pkill -SIGUSR1 waybar"
        # 啟動器
        "$mainMod, D, exec, fuzzel"
        # 終端機
        "$mainMod, Q, exec, kitty"
        # 文件管理器 (回歸 Thunar)
        "$mainMod, E, exec, thunar"
      ];

      # --- 浮動持久化規則 ---
      windowrulev2 = [
        "float, class:(org.fcitx.fcitx5-config-qt)"
        "float, class:(pavucontrol)"
        "float, class:(nm-connection-editor)"
        "float, title:(.*確認.*)"
      ];

      # --- 基礎外觀 ---
      decoration = {
        rounding = 10;
        blur = {
          enabled = true;
          size = 6;
          passes = 2;
        };
      };
    };
  };
}
