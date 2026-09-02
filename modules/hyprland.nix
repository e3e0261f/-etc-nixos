# /etc/nixos/modules/hyprland.nix
{ pkgs, ... }:
{
  wayland.windowManager.hyprland = {
    enable = true;
    # 💡 這樣就不會有那個討厭的警告了
    configType = "hyprlang"; 
    
    settings = {
      "$mainMod" = "SUPER";
      
      # 💡 定義啟動項
      exec-once = [
        "uwsm app -- waybar"
        "uwsm app -- fcitx5 -d"
        "nm-applet --indicator"
      ];

      bind = [
        "$mainMod, Q, exec, kitty"
        "$mainMod SHIFT, Return, exec, chromium" # 👈 你要的快捷鍵
        "$mainMod, D, exec, fuzzel"
        "$mainMod, R, exec, fuzzel"
        "$mainMod, F, togglefloating,"
        "$mainMod SHIFT, F, pin,"
        "$mainMod, W, exec, pkill -SIGUSR1 .waybar-wrapped || pkill -SIGUSR1 waybar"
      ];
      
      # 💡 確保 Fcitx5 視窗自動浮動
      windowrulev2 = [
        "float, class:(org.fcitx.fcitx5-config-qt)"
      ];
    };
  };
}
