{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.helix ];

  environment.etc."xdg/helix/config.toml".text = ''
    theme = "tokyonight"

    [editor]
    line-number = "relative"
    cursor-shape = { insert = "bar", normal = "block" }
    
    [editor.statusline]
    center = ["file-name", "file-modification-indicator"]

    # =========================================================
    # 快捷鍵設定區
    # =========================================================
    [keys.normal]
    # 1. 保存
    "C-s" = ":w"

    # 2. 剪切當前行：改用 Alt + x（絕對不和單字跳躍衝突）
    "A-x" = ["extend_line_below", "delete_selection"]

    # 3. 系統剪貼簿橋樑
    "y" = "yank_joined_to_clipboard"
    "p" = "paste_clipboard_after"
    "P" = "paste_clipboard_before"

    # 4. 註釋
    "C-c" = "toggle_comments"

    # =========================================================
    # 完美的容錯保存退出 (支援所有大小寫組合 zz, zZ, Zz, ZZ)
    # =========================================================
    [keys.normal.z]
    z = ":x"
    Z = ":x"

    [keys.normal.Z]
    z = ":x"
    Z = ":x"
    X = ":q!"
  '';
}
