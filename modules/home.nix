{ pkgs, ... }:

{

  imports = [
    ./fcitx5.nix # 👈 像引用 Crate 一樣把它引入
  ];
  
  home.stateVersion = "24.11"; 

  # --- 1. Waybar 高端膠囊島 ---
  programs.waybar = {
    enable = true;
    systemd.enable = true;
  };

  xdg.configFile."waybar/config.jsonc".text = ''
    {
      "layer": "top", "position": "bottom", "height": 34, "margin-bottom": 8,
      "exclusive": false, "fixed-center": true,
      "modules-center": ["hyprland/workspaces", "pulseaudio", "network", "cpu", "memory", "clock", "tray"]
    }
  '';

  xdg.configFile."waybar/style.css".text = ''
    * { font-family: "JetBrainsMono Nerd Font", "Noto Sans CJK TC"; font-size: 13px; }
    window#waybar { background-color: transparent; transition: all 0.3s; }
    window#waybar.hidden { opacity: 0; margin-bottom: -50px; }
    .modules-center { background: rgba(26, 27, 38, 0.85); border-radius: 20px; padding: 2px 15px; }
    #workspaces, #clock, #pulseaudio { margin: 0 8px; color: #c0caf5; }
  '';

  # --- 2. Fish Shell (合併所有 functions 和 abbrs) ---
  programs.fish = {
    enable = true;
    shellAbbrs = {
      y = "yazi"; zj = "zellij"; top = "btop"; nu = "nushell"; helix = "hx";
    };
    functions = {
      # 代理指令
      proxy = ''
        if test (count $argv) -eq 0
            set -e http_proxy; set -e https_proxy; set -e all_proxy
            echo "🌿 Proxy cleared."
        else
            set -gx http_proxy http://127.0.0.1:$argv[1]
            set -gx https_proxy http://127.0.0.1:$argv[1]
            set -gx all_proxy socks5://127.0.0.1:$argv[1]
            echo "🌐 Proxy set to $argv[1]."
        end
      '';
      # 下載指令
      adl = "aria2c -s 16 -x 16 -k 1M --continue=true $argv";
      fastget = "axel -n 16 -a $argv";
    };
  };

  # --- 3. Helix 編輯器 ---
  programs.helix = {
    enable = true;
    settings = {
      theme = "tokyonight";
      editor = {
        line-number = "relative";
        cursor-shape = { insert = "bar"; normal = "block"; };
        statusline.center = ["file-name" "file-modification-indicator"];
      };
      keys.normal = {
        "Z" = { "Z" = ":x"; "z" = ":x"; };
        "C-s" = ":w";
        "A-x" = ["extend_line_below" "delete_selection"];
        "D" = ["select_all" "delete_selection"];
        "C-S-w" = ["select_all" "delete_selection"];
      };
    };
  };

  # --- 4. 其他現代化工具 ---
  
  # --- 1. 修復 Yazi 警告 ---
  programs.yazi = {
    enable = true;
    enableFishIntegration = true;
    shellWrapperName = "y"; # 👈 加入這行，消除那個 "yy" 轉 "y" 的警告
  };

  # Btop
  programs.btop = {
    enable = true;
    settings = {
      color_theme = "tokyo-night";
      vim_keys = true;
      update_ms = 300;
    };
  };

  # Zellij & Nushell
  programs.zellij.enable = true;
  programs.nushell.enable = true;

  # Alacritty
  programs.alacritty = {
    enable = true;
    settings = {
      window.opacity = 0.85;
      window.padding = { x = 12; y = 12; };
      font.size = 12.0;
    };
  };

  # 5. 軟體包安裝 (排除已在 programs 裡啟用的)
  home.packages = with pkgs; [
    magic-wormhole-rs
    kitty
    aria2
    axel
  ];

    # --- 2. Hyprland 配置 (在這裡加按鍵) ---
  wayland.windowManager.hyprland = {
    enable = true;
    configType = "hyprlang"; # 👈 加入這行，明確告訴系統我們目前用的是傳統語法
    # 這裡的設定會合併到你的 Hyprland 中
    settings = {
      "$mainMod" = "SUPER";
      # --- 1. 快捷鍵區 ---
      bind = [
        # 使用 pkill 發送信號，但要指定正確的進程名
        # 因為 NixOS 有 wrapped 機制，直接 pkill waybar 有時會失效
        "$mainMod, W, exec, pkill -SIGUSR1 .waybar-wrapped || pkill -SIGUSR1 waybar"
      
        # 之前的浮動與 Pin
        "$mainMod, F, togglefloating,"
        "$mainMod SHIFT, F, pin,"
      ];
      # --- 2. 持久化規則區 (這就是你要的記憶功能) ---
      windowrulev2 = [
        # 讓 fcitx5 配置介面永遠浮動
        "float, class:(org.fcitx.fcitx5-config-qt)"
        "float, class:(fcitx5-config-viewer)"
        
        # 讓所有的彈窗、對話框永遠浮動
        "float, title:(.*Open File.*)"
        "float, title:(.*File Upload.*)"
        
        # 範例：如果你希望特定的終端機或是軟體也持久浮動
        # "float, class:(pavucontrol)"  # 音量控制
        # "float, class:(blueman-manager)" # 藍牙管理
      ];
    };
  };
  

  }
