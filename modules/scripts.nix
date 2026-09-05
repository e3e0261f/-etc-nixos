{ pkgs, ... }:

{
  # 💡 確保這是一個標準的 Home Manager 用戶模組
  home.packages = [

        (pkgs.writeScriptBin "record-screen" ''
      #!${pkgs.bash}/bin/bash

      RECORD_DIR="$HOME/Videos/Recordings"
      mkdir -p "$RECORD_DIR"

      # 1. 檢查是否正在錄影。如果是，優雅停止並封裝 MP4
      if pgrep -x "wf-recorder" > /dev/null; then
          pkill -INT -x wf-recorder
          ${pkgs.libnotify}/bin/notify-send "🎬 錄影已完成" "已儲存含聲音的影片至 $RECORD_DIR" -i media-record
          exit 0
      fi

      TIMESTAMP=$(date "+%Y%m%d_%H%M%S")
      FILENAME="$RECORD_DIR/rec_$TIMESTAMP.mp4"

      # 💡 關鍵：精確捕捉電腦當前輸出的立體聲音訊（YouTube、播放器、遊戲聲音）
      AUDIO_FLAGS="--audio=alsa_output.pci-0000_00_1b.0.analog-stereo.monitor -C aac"

      # 2. 判斷模式並啟動錄製
      if [ "$1" == "area" ]; then
          GEOM=$(${pkgs.slurp}/bin/slurp)
          if [ -z "$GEOM" ]; then
              exit 0
          fi
          ${pkgs.libnotify}/bin/notify-send "🔴 開始【區域+系統聲音】錄影" "再次按下快捷鍵即可停止" -i media-record
          ${pkgs.wf-recorder}/bin/wf-recorder $AUDIO_FLAGS -g "$GEOM" -f "$FILENAME"
      else
          ${pkgs.libnotify}/bin/notify-send "🔴 開始【全螢幕+系統聲音】錄影" "再次按下快捷鍵即可停止" -i media-record
          ${pkgs.wf-recorder}/bin/wf-recorder $AUDIO_FLAGS -f "$FILENAME"
      fi
    '')

    
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
