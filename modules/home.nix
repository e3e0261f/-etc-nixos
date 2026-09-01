{ pkgs, ... }:

{
  home.stateVersion = "24.11"; 

  # --- 1. Waybar 高端膠囊島配置 ---
  programs.waybar = {
    enable = true;
    systemd.enable = true; # 讓 HM 自動管理服務
  };

  xdg.configFile."waybar/config.jsonc".text = ''
    {
      "layer": "top",
      "position": "bottom",
      "height": 34,
      "margin-bottom": 8,
      "exclusive": false,   // 懸浮模式，不推擠視窗
      "fixed-center": true,
      
      "modules-center": [
        "hyprland/workspaces",
        "hyprland/window",
        "pulseaudio",
        "network",
        "cpu",
        "memory",
        "clock",
        "tray"
      ],

      "hyprland/workspaces": {
        "format": "{name}",
        "on-click": "activate"
      },
      "clock": {
        "format": " {:%H:%M}",
        "tooltip-format": "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>"
      },
      "pulseaudio": {
        "format": "{icon} {volume}%",
        "format-muted": "󰝟 Muted",
        "format-icons": {
          "default": ["", "", ""]
        },
        "on-click": "pavucontrol"
      },
      "cpu": { "format": " {usage}%" },
      "memory": { "format": " {used}G" },
      "network": {
        "format-wifi": " {essid}",
        "format-ethernet": "󰈀 Wired",
        "format-disconnected": "⚠ Disconnected"
      },
      "tray": {
        "icon-size": 16,
        "spacing": 10
      }
    }
  '';

  xdg.configFile."waybar/style.css".text = ''
    /* 全域字體 */
    * {
        font-family: "JetBrainsMono Nerd Font", "Noto Sans CJK TC", sans-serif;
        font-size: 13px;
    }

    /* 隱身容器：平時透明 */
    window#waybar {
        background-color: transparent;
        transition: all 0.3s ease-in-out;
    }

    /* 隱藏狀態：Super+W 觸發後滑下去並消失 */
    window#waybar.hidden {
        opacity: 0;
        margin-bottom: -50px;
    }

    /* 膠囊本體：居中島嶼 */
    .modules-center {
        background-color: rgba(26, 27, 38, 0.85); /* 深色半透明 */
        border: 1px solid rgba(255, 255, 255, 0.1);
        border-radius: 20px;
        padding: 2px 15px;
        box-shadow: 0 4px 12px rgba(0, 0, 0, 0.5);
    }

    /* 各個模組樣式 */
    #workspaces, #clock, #pulseaudio, #network, #cpu, #memory, #tray, #window {
        margin: 0 8px;
        color: #c0caf5;
    }

    #workspaces button {
        padding: 0 5px;
        color: #565f89;
    }

    #workspaces button.active {
        color: #7aa2f7;
        font-weight: bold;
    }

    #clock { color: #bb9af7; }
    #pulseaudio { color: #7aa2f7; }
  '';

  # --- 2. Fish Proxy 魔法指令 ---
  programs.fish = {
    enable = true;

    functions = {
      # 1. adl (Aria2 Download): 自動開啟 16 線程，且支援斷點續傳
      adl = ''
        aria2c -s 16 -x 16 -k 1M --continue=true --console-log-level=warn --summary-interval=0 $argv
      '';

      # 2. fastget (Axel Download): 極簡多線程，適合單一檔案
      fastget = ''
        axel -n 16 -a $argv
      '';
    };

    functions = {
      proxy = ''
        if test (count $argv) -eq 0
            set -e http_proxy; set -e https_proxy; set -e all_proxy
            echo "🌿 Proxy cleared. Mode: Direct"
        else
            set -gx http_proxy http://127.0.0.1:$argv[1]
            set -gx https_proxy http://127.0.0.1:$argv[1]
            set -gx all_proxy socks5://127.0.0.1:$argv[1]
            echo "🌐 Proxy set to port $argv[1]. Mode: Global"
        end
      '';
    };
  };


    programs.alacritty = {
    enable = true;
    settings = {
      # 1. 透明度設定 (0.0 到 1.0)
      window.opacity = 0.85; 

      # 2. 視窗內邊距 (讓文字不要貼著邊緣，更有設計感)
      window.padding = {
        x = 12;
        y = 12;
      };

      # 3. 字體設定
      font = {
        size = 12.0;
        normal = {
          family = "JetBrainsMono Nerd Font";
          style = "Regular";
        };
      };

      # 4. 配色方案 (可選，推薦 Tokyo Night 或 Dracula)
      colors = {
        primary = {
          background = "#1a1b26"; # 深色背景配透明度效果最好
          foreground = "#c0caf5";
        };
      };
    };
  };

  # --- 3. 讓 Neovim 使用你的使用者配色 (可選) ---
  # 你也可以在這裡加上其他個人軟體的配置
}
