{ pkgs, ... }:

{
  programs.waybar = {
    enable = true;
    systemd.enable = true;
  };

  xdg.configFile."waybar/config.jsonc".text = ''
    {
      "layer": "top",
      "position": "bottom",
      "height": 34,
      "margin-bottom": 8,
      "exclusive": false,
      "fixed-center": true,
      "ipc": true,
      "modules-center": [
        "hyprland/workspaces",
        "pulseaudio",
        "network",
        "cpu",
        "memory",
        "custom/clock-it",
        "tray"
      ],
      "custom/clock-it": {
        "exec": "date '+第%V週 | %m/%d %A | %H:%M'",
        "interval": 60
      },
      "pulseaudio": {
        "format": "{icon} {volume}%",
        "format-icons": { "default": ["", "", ""] }
      }
    }
  '';

  xdg.configFile."waybar/style.css".text = ''
    * { font-family: "JetBrainsMono Nerd Font", "Noto Sans CJK TC"; font-size: 13px; }
    window#waybar { background-color: transparent; transition: all 0.3s; }
    window#waybar.hidden { opacity: 0; margin-bottom: -50px; }
    .modules-center { background: rgba(26, 27, 38, 0.85); border-radius: 20px; padding: 2px 15px; }
  '';
}
