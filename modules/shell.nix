
{ pkgs, ... }:

{
  programs.fish = {
    enable = true;

    # 1. 互動式終端啟動邏輯（自動加載 zoxide 與 TTY 圖標判斷）
    interactiveShellInit = ''
      # 載入 zoxide (如果已安裝)
      if command -v zoxide >/dev/null 2>&1
        zoxide init fish | source
      end
    '';
  
    shellAbbrs = {
      gcd = "git clone --depth 1";
      top = "btop"; 
      nu = "nushell"; 
      helix = "hx";
      al = "a -l";
      aa = "a -a";
      as = "a -s";
      l = "eza -la";
      ls = "eza";
      ll = "eza -la --git";
      tree = "eza --tree";
    };

    functions = {
      logout = ''
        command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'
      '';
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

      sss = ''
        set filename ~/Pictures/(date +%Y%m%d_%H%M%S).png
        grim -g "(slurp)" $filename
        echo "📸 截圖已儲存至 $filename"
      '';

      cc = ''
        set -l count 0
        if test (count $argv) -eq 0
            set -l target_dirs "$HOME/下載" "$HOME/Downloads"
            for d in $target_dirs
                if test -d "$d"
                    echo "🔍 正在掃描目錄: $d ..."
                    find "$d" -type f -iname "*.srt" | while read -l f
                        if string match -q "*.srt.txt" "$f"; continue; end
                        opencc -i "$f" -o "$f.txt" -c s2twp.json
                        echo "✨ 轉繁成功: $f.txt"
                        diff --color=always -u "$f" "$f.txt"
                        set count (math $count + 1)
                    end
                end
            end
            if test $count -eq 0; echo "📭 沒有找到任何需要轉換的 .srt 檔案。"; end
        else
            set f $argv[1]
            if test -f "$f"
                opencc -i "$f" -o "$f.txt" -c s2twp.json
                echo "✨ 單檔轉繁成功: $f.txt"
                diff --color=always -u "$f" "$f.txt"
            else
                echo "❌ 找不到檔案: $f"
            end
        end
        echo "🎉 所有轉換與對比搞定！"
      '';
    };
  };

  programs.nushell.enable = true;
}
