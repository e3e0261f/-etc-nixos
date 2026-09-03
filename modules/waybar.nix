{ pkgs, ... }:

{
  programs.waybar = {
    enable = true;
    systemd = {
      enable = true;
      targets = [ "graphical-session.target" ];
    };
  };

  xdg.configFile."waybar/config.jsonc".text = ''
    {
      "layer": "top",
      "position": "bottom",
      "height": 38,             // 💡 稍微增加一點高度容納雙行
      "margin-bottom": 8,
      "exclusive": false,
      "fixed-center": true,
      "ipc": true,
      "modules-center": [
        "hyprland/workspaces",
        "custom/population",    // 👈 雙行世界人口模組
        "pulseaudio",
        "network",
        "cpu",
        "memory",
        "clock",
        "tray"
      ],

      // 💡 雙行人口模組配置
      "custom/population": {
        "exec": "awk 'BEGIN{printf \"%.0f\\nPPL\\n\", 8185000000 + (systime() - 1704067200)*2.4}'",
        "format": "{}",
        "interval": 2,          // 每 2 秒刷新一次人口數據
        "tooltip": false
      },

      "hyprland/workspaces": {
        "format": "{name}",
        "on-click": "activate"
      },
      "pulseaudio": {
        "format": "  {volume}%",
        "format-muted": "󰝟 Muted",
        "on-click": "pavucontrol"
      },
      "network": {
        "format-wifi": "  {essid}",
        "format-ethernet": "󰈀 Wired",
        "format-disconnected": "⚠ Disconnected"
      },
      "cpu": {
        "format": "  {usage}%",
        "interval": 2
      },
      "memory": {
        "format": "  {percentage}%",
        "interval": 2
      },
      "clock": {
        "format": "  {:%H:%M}"
      },
      "tray": {
        "icon-size": 16,
        "spacing": 8
      }
    }
  '';

  xdg.configFile."waybar/style.css".text = ''
    * {
        font-family: "JetBrainsMono Nerd Font", "Noto Sans CJK TC";
        font-size: 13px;
    }

    window#waybar {
        background-color: transparent;
        transition: all 0.3s;
    }

    window#waybar.hidden {
        opacity: 0;
        margin-bottom: -50px;
    }

    .modules-center {
        background: rgba(26, 27, 38, 0.85);
        border: 1px solid rgba(255, 255, 255, 0.1);
        border-radius: 20px;
        padding: 2px 16px;
        box-shadow: 0 4px 12px rgba(0, 0, 0, 0.5);
    }

    #workspaces, #custom-population, #pulseaudio, #network, #cpu, #memory, #clock, #tray {
        margin: 0 10px;
        color: #c0caf5;
    }

    /* 💡 雙行專屬樣式：緊湊行高與精緻字體 */
    #custom-population {
        font-size: 11px;
        font-weight: bold;
        color: #7aa2f7;
        margin: 0 8px;
    }

    #cpu { color: #7dcfff; }
    #memory { color: #bb9af7; }
    #network { color: #9ece6a; }
    #clock { color: #e0af68; }
    #pulseaudio { color: #7aa2f7; }
  '';
}
