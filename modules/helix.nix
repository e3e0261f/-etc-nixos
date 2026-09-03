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
    # 1. 保存 (已驗證正確)
    "C-s" = ":w"

    # 2. 剪切當前行：改為大寫 W
    "W" = ["extend_line_below", "delete_selection"]

    # 3. 系統剪貼簿橋樑
    "y" = "yank_joined_to_clipboard"
    "p" = "paste_clipboard_after"
    "P" = "paste_clipboard_before"

    # 4. 註釋快捷鍵
    "C-c" = "toggle_comments"

    # =========================================================
    # 保存並退出 (對應 Vim 的 ZZ / ZQ)
    # =========================================================
    [keys.normal.Z]
    Z = ":x"
    z = ":x"
    X = ":q!"
  '';
}
