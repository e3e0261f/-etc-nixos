{ pkgs, ... }:

{
  programs.kitty = {
    enable = true;
    
    # 💡 1. 設置字體與大小
    font = {
      name = "JetBrainsMono Nerd Font";
      size = 24; # 👈 字號直接設定為 24
    };

    settings = {
      # 💡 2. 也可以在 settings 裡明確指定
      font_size = 24;
      
      background_opacity = "0.85";
      window_padding_width = 10;
      copy_on_select = "clipboard";
    };

    keybindings = {
      "ctrl+shift+c" = "copy_to_clipboard";
      "ctrl+shift+v" = "paste_from_clipboard";
    };
  };
}
