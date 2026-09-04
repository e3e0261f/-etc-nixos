{ pkgs, ... }:

{
  # 💡 確保這是一個標準的 Home Manager 用戶模組
  home.packages = [
    # --- trans-gui: 大字體互動式截圖翻譯工具 (極速 1 秒修正版) ---
    (pkgs.writeScriptBin "trans-gui" ''
      #!${pkgs.bash}/bin/bash
      
      # 1. 截圖並進行 OCR 識別
      ${pkgs.grim}/bin/grim -g "$(${pkgs.slurp}/bin/slurp)" /tmp/sel.png
      ${pkgs.tesseract}/bin/tesseract /tmp/sel.png /tmp/out -l eng 2>/dev/null
      
      # 2. 💡 修正：使用 -f 直接讀取檔案，並改用極速的 bing 引擎 (或去掉 -e 讓它自動跟隨你設定的預設引擎)
      result=$(${pkgs.crow-translate}/bin/crow -e bing -t zh-CN -b -f /tmp/out.txt 2>/dev/null)
      
      # 3. 自動把翻譯結果送入系統剪貼簿
      echo "$result" | ${pkgs.wl-clipboard}/bin/wl-copy
      
      # 4. YAD 彈出精美對話框
      echo "$result" | ${pkgs.yad}/bin/yad --text-info \
        --title="翻譯結果" \
        --width=600 \
        --height=350 \
        --fontname="Noto Sans CJK TC 18" \
        --wrap \
        --button="關閉":0
    '')
  ];
}
