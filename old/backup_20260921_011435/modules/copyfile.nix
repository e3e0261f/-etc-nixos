# /etc/nixos/modules/copyfile.nix
{ pkgs, ... }:

let
  copyfile = pkgs.writeShellScriptBin "copyfile" ''
    #!/usr/bin/env bash
    set -e

    CACHE_DIR="/tmp/copyfile-cache"
    mkdir -p "$CACHE_DIR"

    # ⭐️ 失敗時的 Mako 紅色緊急通知
    notify_err() {
        echo "❌ $1" >&2
        ${pkgs.libnotify}/bin/notify-send \
            -u critical \
            -i dialog-error \
            -t 4000 \
            "❌ 剪貼簿複製失敗" "$1"
        exit 1
    }

    # ⭐️ 成功時的 Mako 綠色/常規通知
    notify_ok() {
        echo "📋 $1"
        ${pkgs.libnotify}/bin/notify-send \
            -t 3000 \
            -i edit-copy \
            "📋 剪貼簿已就緒" "$1\n$2"
    }

    # 1. 檢查參數是否為空
    if [ $# -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        notify_err "未指定檔案！用法: copyfile <檔案> [新檔名]"
    fi

    MIME_TYPE="text/uri-list"
    MODE_NAME="可在 Dolphin / Discord / 瀏覽器 直接 Ctrl+V 貼上"

    # 2. 改名複製模式 (剛好 2 個參數，前存在，後不存在)
    if [ $# -eq 2 ] && [ -e "$1" ] && [ ! -e "$2" ]; then
        SRC_FILE="$1"
        NEW_NAME="$2"
        SRC_ABS="$(${pkgs.coreutils}/bin/realpath "$SRC_FILE" 2>/dev/null)" || notify_err "無法解析檔案路徑: $SRC_FILE"

        TARGET_PATH="$CACHE_DIR/$NEW_NAME"
        rm -f "$TARGET_PATH"
        cp -L "$SRC_ABS" "$TARGET_PATH" || notify_err "無法將檔案寫入暫存快取"

        if echo "file://$TARGET_PATH" | ${pkgs.wl-clipboard}/bin/wl-copy -t text/uri-list; then
            notify_ok "已改名複製：$(basename "$SRC_FILE") ➜ $NEW_NAME" "$MODE_NAME"
            exit 0
        else
            notify_err "寫入 Wayland 剪貼簿失敗！"
        fi
    fi

    # 3. 常規多檔案複製模式：先嚴格檢查所有檔案是否存在
    for file in "$@"; do
        if [ ! -e "$file" ]; then
            notify_err "找不到檔案：$file"
        fi
    done

    # 寫入剪貼簿
    if {
        for file in "$@"; do
            echo "file://$(${pkgs.coreutils}/bin/realpath "$file")"
        done
    } | ${pkgs.wl-clipboard}/bin/wl-copy -t text/uri-list; then
        if [ $# -eq 1 ]; then
            notify_ok "已複製檔案：$(basename "$1")" "$MODE_NAME"
        else
            notify_ok "已批次複製 $# 個檔案到剪貼簿！" "$MODE_NAME"
        fi
    else
        notify_err "寫入 Wayland 剪貼簿失敗！"
    fi
  '';
in
{
  home.packages = [
    copyfile
    pkgs.libnotify
    pkgs.wl-clipboard
  ];

  xdg.configFile."fish/completions/copyfile.fish".text = ''
    complete -c copyfile -s h -l help -d "顯示幫助訊息"
    complete -c copyfile -F
  '';
}
