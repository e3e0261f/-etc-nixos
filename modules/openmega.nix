
{ pkgs, ... }:

{
  # 裝載所有與 OpenCC、MEGA 和下載相關的依賴包
  home.packages = with pkgs; [
    megacmd
    opencc
    git-delta
    aria2
    axel
  ];

  # 將相關的 Fish 腳本集中管理
  programs.fish.functions = {
    # 1. MEGA 自動下載與翻譯腳本
    mega-srt = ''
      if test (count $argv) -eq 0
          echo "⚠️ 用法: mega-srt <MEGA資料夾連結>"
          return
      end
      set link (string trim -r -c '/' "$argv[1]")
      echo "🔐 正在連接 MEGA 伺服器並解析加密目錄..."
      set srt_files (mega-ls "$link" 2>/dev/null | grep -i "\.srt$")

      if test (count $srt_files) -eq 0
          echo "📭 該連結中沒有找到任何 .srt 檔案！"
          return
      end

      echo "🎯 準備精準提取字幕檔..."
      for f in $srt_files
          echo "⬇️ 下載中: $f"
          mega-get "$link/$f" ./
      end

      echo "✅ 下載完成！啟動自動轉繁..."
      for f in $srt_files
          if test -f "$f"
              opencc -i "$f" -o "$f.txt" -c s2twp.json
              echo "✨ [$f] 轉繁完成 -> $f.txt"
          end
      end
      echo "🎉 全部執行完畢！"
    '';

    # 2. 自動在地化翻譯腳本 (帶 Delta 差異對比)
    cc = ''
      set -l count 0
      if test (count $argv) -eq 0
          set -l target_dirs "$HOME/下載" "$HOME/Downloads"
          for d in $target_dirs
              if test -d "$d"
                  echo "🔍 掃描目錄: $d ..."
                  find "$d" -type f -iname "*.srt" | while read -l f
                      if string match -q "*.srt.txt" "$f"; continue; end
                      opencc -i "$f" -o "$f.txt" -c s2twp.json
                      echo "✨ 轉繁成功: $f.txt"
                      echo "📊 內容差異對比 (-:簡體 | +:繁體):"
                      diff --color=always -u "$f" "$f.txt" | head -n 20
                      set count (math $count + 1)
                  end
              end
          end
          if test $count -eq 0; echo "📭 無需轉換的檔案。"; end
      else
          set f $argv[1]
          if test -f "$f"
              opencc -i "$f" -o "$f.txt" -c s2twp.json
              echo "✨ 轉繁成功: $f.txt"
              diff --color=always -u "$f" "$f.txt"
          else
              echo "❌ 找不到檔案: $f"
          end
      end
    '';

    # 3. 基礎下載工具
    adl = "aria2c -s 16 -x 16 -k 1M --continue=true $argv";
    fastget = "axel -n 16 -a $argv";
  };
}
