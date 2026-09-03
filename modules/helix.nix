{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.helix ];

  # 全系統共用的 Helix 配置 (確保 root 和 rhys 都能用)
  environment.etc."xdg/helix/config.toml".text = ''
    theme = "tokyonight"

    [editor]
    line-number = "relative"
    cursor-shape = { insert = "bar", normal = "block" }
    
    [editor.statusline]
    center = ["file-name", "file-modification-indicator"]

    # =========================================================
    # 快捷鍵對應區 (Keys Normal Mode)
    # =========================================================
    [keys.normal]
    # 1. 保存檔案
    "C-s" = ":w"

    # 2. 剪切當前行 (替代原本衝突的 Ctrl+w，改用 Alt+x)
    "A-x" = ["extend_line_below", "delete_selection"]

    # 3. 清空並剪切全部文本 (Ctrl + Shift + w)
    "C-S-w" = ["select_all", "delete_selection"]
    "D" = ["select_all", "delete_selection"]

    # 4. 系統剪貼簿橋樑
    "y" = "yank_joined_to_clipboard"
    "p" = "paste_clipboard_after"
    "P" = "paste_clipboard_before"

    # =========================================================
    # 子選單：大寫 Z 開頭的保存與退出 (對應 Vim 的 ZZ / ZQ)
    # =========================================================
    [keys.normal.Z]
    Z = ":x"
    z = ":x"
    X = ":q!"
  '';
}
