{ pkgs, ... }:

{

  imports = [
    ./fcitx5.nix # 👈 像引用 Crate 一樣把它引入
    #./hyprland.nix # 👈 插入新模組
    ./waybar.nix # 👈 插入新模組
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
    
    # 1. 簡單的縮寫 (Abbrs) - 裡面不要有雙引號嵌套或複雜變數
    shellAbbrs = {
      gcl  = "git clone --depth 1";
      l    = "ls -alh";
      ll   = "ls -l";
      ls   = "ls --color=tty";
      y    = "yazi"; 
      zj   = "zellij"; 
      top  = "btop"; 
      nu   = "nushell"; 
      helix = "hx";
    };

    # 2. 複雜的指令，改成用 functions 定義 (安全、易讀、不會引發 Nix 解析崩潰)
    functions = {
      # 代理指令
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

      # 截圖存檔指令 (替代原本複雜的 sss)
      sss = ''
        set filename ~/Pictures/(date +%Y%m%d_%H%M%S).png
        grim -g "(slurp)" $filename
        echo "📸 截圖已儲存至 $filename"
      '';

      # 世代查詢 (替代原本的 nix-rollback)
      nix-bac = ''
        sudo nix-env --list-generations --profile /nix/var/nix/profiles/system
      '';
    };
  };


  # --- 3. Helix 編輯器 ---
  programs.helix = {
    enable = true;
    settings = {
      # ... 其他 editor 設定保持不變 ...
      keys.normal = {
        # --- 修正後的剪貼簿指令 ---
        "y" = "yank_to_clipboard";
        "p" = "paste_clipboard_after";
        "P" = "paste_clipboard_before";
        # 💡 如果 R 報錯，我們暫時不用它，或者改用這個組合：
        "R" = ["delete_selection" "paste_clipboard_before"]; 

        # --- 你原本的其他快捷鍵 ---
        "C-s" = ":w";
        "Z" = { "Z" = ":x"; "z" = ":x"; "X" = ":q!"; };
        "A-x" = ["extend_line_below" "delete_selection"];
        "D" = ["select_all" "delete_selection"];
        "C-S-w" = ["select_all" "delete_selection"];
        "C-c" = "toggle_comments";
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

  programs.kitty = {
    enable = true;
    settings = {
      copy_on_select = "yes"; # 👈 滑鼠選中就自動複製
    };
  };

  programs.git = {
    enable = true;
    
    # 💡 簽名部分目前保持原樣即可
    signing = {
      key = "31C81A9DE1AB870A8EDC3486D7C2DF9FA0283056";
      signByDefault = true;
    };

    # 💡 關鍵修正：將資訊移入 settings
    settings = {
      user = {
        name = "kevin lee";
        email = "e3e0261f@pm.me";
      };
      
      init.defaultBranch = "main";
      commit.gpgsign = true;

      # 魔法 SSH 轉向
      url."git@github.com:".insteadOf = "https://github.com/";
    };
  };

  # 5. 軟體包安裝 (排除已在 programs 裡啟用的)
  home.packages = with pkgs; [
    magic-wormhole-rs
    kitty
    aria2
    axel
  ];

}
