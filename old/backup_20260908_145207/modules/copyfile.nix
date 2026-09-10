# /etc/nixos/modules/copyfile.nix
{ pkgs, ... }:

let
  copyfile = pkgs.writeShellScriptBin "copyfile" ''
    #!/usr/bin/env bash
    set -e

    CACHE_DIR="/tmp/copyfile-cache"
    mkdir -p "$CACHE_DIR"

    if [ $# -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        echo "❌ 用法:"
        echo "  copyfile <檔案1> [檔案2...]          (原名複製)"
        echo "  copyfile <原檔案> <新檔案名稱>       (改名複製到剪貼簿)"
        exit 1
    fi

    # ⭐️ 核心修復：預設採用 Dolphin、瀏覽器、Discord 100% 相容的標準 URI 格式！
    MIME_TYPE="text/uri-list"

    # 改名複製模式 (2個參數，前存在，後不存在)
    if [ $# -eq 2 ] && [ -e "$1" ] && [ ! -e "$2" ]; then
        SRC_FILE="$1"
        NEW_NAME="$2"
        SRC_ABS="$(${pkgs.coreutils}/bin/realpath "$SRC_FILE")"

        TARGET_PATH="$CACHE_DIR/$NEW_NAME"
        rm -f "$TARGET_PATH"
        cp -L "$SRC_ABS" "$TARGET_PATH"

        echo "file://$TARGET_PATH" | ${pkgs.wl-clipboard}/bin/wl-copy -t text/uri-list
        echo "📋 已將檔案 [$SRC_FILE] 改名為 [$NEW_NAME] 複製到剪貼簿！"
        exit 0
    fi

    # 常規多檔案複製模式
    for file in "$@"; do
        if [ ! -e "$file" ]; then
            echo "❌ 錯誤：檔案不存在 -> $file" >&2
            exit 1
        fi
    done

    {
        for file in "$@"; do
            echo "file://$(${pkgs.coreutils}/bin/realpath "$file")"
        done
    } | ${pkgs.wl-clipboard}/bin/wl-copy -t text/uri-list

    if [ $# -eq 1 ]; then
        echo "📋 已成功複製檔案：$1 （可在 Dolphin/網頁直接貼上）！"
    else
        echo "📋 已成功複製以下 $# 個檔案："
        for file in "$@"; do
            echo "   📄 $file"
        done
    fi
  '';
in
{
  home.packages = [
    copyfile
  ];

  xdg.configFile."fish/completions/copyfile.fish".text = ''
    complete -c copyfile -s h -l help -d "顯示幫助訊息"
    complete -c copyfile -F
  '';
}
