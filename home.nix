{
  home.pointerCursor = {
    gtk.enable = true;
    # x11.enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Classic";
    size = 16;
  };
  # 在 home.nix 中配置
  xdg.userDirs = {
    enable = true;
    createDirectories = true; # 讓系統自動幫你建好英文目錄
    desktop = "$HOME/Desktop";
    documentation = "$HOME/Documents";
    download = "$HOME/Downloads";
    music = "$HOME/Music";
    pictures = "$HOME/Pictures";
    videos = "$HOME/Videos";
  };
  wayland.windowManager.hyprland = {
  enable = true;
  # 必须关闭 home-manager 自带的 systemd 注入，由 UWSM 接管
  systemd.enable = false; 
  };
  gtk = {
    enable = true;

    theme = {
      package = pkgs.flat-remix-gtk;
      name = "Flat-Remix-GTK-Grey-Darkest";
    };

    iconTheme = {
      package = pkgs.adwaita-icon-theme;
      name = "Adwaita";
    };

    font = {
      name = "Sans";
      size = 11;
    };
  };
}
