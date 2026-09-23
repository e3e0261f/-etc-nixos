# /etc/nixos/modules/zsh.nix
{ pkgs, ... }:

{
  # 1. 啟用系統級 Zsh 與現代化神級插件
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestions.enable = true;    # ⭐️ 灰字幽靈預測（按 → 或 Ctrl+E 補全）
    syntaxHighlighting.enable = true; # ⭐️ 即時語法高亮（正確變綠，打錯變紅）

    # 極客級歷史記錄調教
    histSize = 100000;
    histFile = "$HOME/.zsh_history";
    setOptions = [
      "EXTENDED_HISTORY"       # 記錄時間戳
      "HIST_IGNORE_ALL_DUPS"   # 自動去重
      "HIST_SAVE_NO_DUPS"      # 存檔去重
      "SHARE_HISTORY"          # 多終端視窗即時共享歷史
      "INC_APPEND_HISTORY"     # 立即寫入歷史
      "AUTO_CD"                # 敲目錄名字直接進去（省略 cd）
    ];

    # === ⭐️ 現代化四大神器 + 終極日常別名 ===
    shellAliases = {
      # 📁 1. eza 矩陣（取代傳統 ls，自帶圖標、目錄優先、Git 狀態）
      ls   = "eza --icons --group-directories-first";
      l    = "eza -l --icons --group-directories-first";
      ll   = "eza -la --icons --git --group-directories-first";
      la   = "eza -a --icons --group-directories-first";
      tree = "eza --tree --icons";
      lt   = "eza --tree --level=2 --icons";

      # 📖 2. bat 矩陣（取代傳統 cat，自帶語法高亮與行號）
      cat  = "bat --paging=never";
      catp = "bat -p";
      less = "bat";

      # 🔍 3. fd 矩陣（取代傳統 find，極速搜索）
      find = "fd";
      fda  = "fd -I -H";

      # ⚡ 4. ripgrep 矩陣（取代傳統 grep，全世界最快正則檢索）
      grep = "rg";
      rgi  = "rg -i";
      rgf  = "rg --files";

      # 🛠️ 5. 其他極客高頻縮寫
      top   = "btop";
      gcd   = "git clone --depth 1";
      nu    = "nushell";
      helix = "hx";
      al    = "a -l";
      aa    = "a -a";
      as    = "a -s";
    };

    # === ⭐️ 終端初始化腳本（包含 GPG Agent 與所有自訂函數）===
    interactiveShellInit = ''
      # 1. 綁定 GPG SSH 代理（讓 GPG 密鑰直接當 SSH 密鑰用）
      export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket 2>/dev/null)

      # 2. 登出 / 關機快捷
      logout() {
        command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'
      }

      # 3. 代理快速切換（直連 / 全域）
      proxy() {
        if [ $# -eq 0 ]; then
          unset http_proxy https_proxy all_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY
          echo "🌿 Proxy cleared. Mode: Direct"
        else
          export http_proxy="http://127.0.0.1:$1"
          export https_proxy="http://127.0.0.1:$1"
          export all_proxy="socks5://127.0.0.1:$1"
          export HTTP_PROXY="http://127.0.0.1:$1"
          export HTTPS_PROXY="http://127.0.0.1:$1"
          export ALL_PROXY="socks5://127.0.0.1:$1"
          echo "🌐 Proxy set to port $1. Mode: Global"
        fi
      }

      # 4. 一鍵選區定格截圖
      sss() {
        local filename="$HOME/Pictures/$(date +%Y%m%d_%H%M%S).png"
        mkdir -p "$HOME/Pictures"
        grim -g "$(slurp)" "$filename"
        echo "📸 截圖已儲存至 $filename"
      }

      # 5. OpenCC 繁簡字幕轉換與彩色比對
      cc() {
        local count=0
        if [ $# -eq 0 ]; then
          local target_dirs=("$HOME/下載" "$HOME/Downloads")
          for d in "''${target_dirs[@]}"; do
            if [ -d "$d" ]; then
              echo "🔍 正在掃描目錄: $d ..."
              find "$d" -type f -iname "*.srt" | while IFS= read -r f; do
                [[ "$f" == *.srt.txt ]] && continue
                opencc -i "$f" -o "$f.txt" -c s2twp.json
                echo "✨ 轉繁成功: $f.txt"
                diff --color=always -u "$f" "$f.txt"
                ((count++))
              done
            fi
          done
          [ "$count" -eq 0 ] && echo "📭 沒有找到任何需要轉換的 .srt 檔案。"
        else
          local f="$1"
          if [ -f "$f" ]; then
            opencc -i "$f" -o "$f.txt" -c s2twp.json
            echo "✨ 單檔轉繁成功: $f.txt"
            diff --color=always -u "$f" "$f.txt"
          else
            echo "❌ 找不到檔案: $f"
          fi
        fi
        echo "🎉 所有轉換與對比搞定！"
      }
    '';
  };

  # 2. 啟用智能目錄跳躍 zoxide
  programs.zoxide = {
    enable = true;
  };

  # 3. 啟用跨終端 Starship 提示符
  programs.starship = {
    enable = true;
  };
}
