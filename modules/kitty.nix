{ pkgs, ... }:

{
  programs.kitty = {
    enable = true;
    settings = {
      # 終端機透明度 (呼應你的 Hyprland 磨砂玻璃)
      background_opacity = "0.85";
      window_padding_width = 10;
      
      # 支援滑鼠選中即複製到系統剪貼簿
      copy_on_select = "clipboard";
    };
    
    keybindings = {
      "ctrl+shift+c" = "copy_to_clipboard";
      "ctrl+shift+v" = "paste_from_clipboard";
    };
  };
}
