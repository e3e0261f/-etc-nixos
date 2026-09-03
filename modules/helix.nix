{ pkgs, ... }:

{
  # 讓 Home Manager 完美接管 ~/.config/helix/config.toml
  programs.helix = {
    enable = true;
    settings = {
      theme = "tokyonight";
      editor = {
        line-number = "relative";
        cursor-shape = {
          insert = "bar";
          normal = "block";
        };
      };

      keys.normal = {
        "C-s" = ":w";
        "y" = "yank_joined_to_clipboard";
        "p" = "paste_clipboard_after";
        "P" = "paste_clipboard_before";
        "C-c" = "toggle_comments";

        # 領導者選單：Space + z (保存退出), Space + x (不保存退出)
        space = {
          z = ":x";
          x = ":q!";
        };
      };
    };
  };
}
