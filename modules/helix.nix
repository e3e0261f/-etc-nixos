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
    # 快捷鍵設定區 (全面擁抱 Space 與 Alt，告別失靈的 Shift)
    # =========================================================
    [keys.normal]
    # 1. 快速保存 (Ctrl + s)
    "C-s" = ":w"

    # 2. 剪切當前行 (Alt + x，極速順手)
    "A-x" = ["extend_line_below", "delete_selection"]

    # 3. 系統剪貼簿橋樑
    "y" = "yank_joined_to_clipboard"
    "p" = "paste_clipboard_after"
    "P" = "paste_clipboard_before"

    # 4. 註釋
    "C-c" = "toggle_comments"

    # =========================================================
    # 領導者選單：Space 鍵開頭的極速退出方案
    # =========================================================
    # 按下 Space 之後：
    #   按 z ➡ 保存並退出 (:x)
    #   按 x ➡ 強制退出不保存 (:q!)
    [keys.normal.space]
    z = ":x"
    x = ":q!"
  '';
}
