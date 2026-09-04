{ pkgs, ... }:

{
  # 🎯 這裡成了唯一的「插線板 / 總路由」
  imports = [
    # ./fcitx-ibus.nix
    ./hyprland.nix
    ./waybar.nix
    ./openmega.nix
    ./kitty.nix
    ./shell.nix
    ./tools.nix
    ./helix.nix
    ./git.nix
    ./fcitx5.nix
    ./mako.nix
    ./fuzzel.nix
    ./scripts.nix
  ];

  home.sessionVariables = {
    # 這是所有 GTK 程式 (包含你彈出的通知、輸入法設定) 的字體大小總開關
    GTK_FONT_NAME = "Noto Sans CJK TC 16";
  };

  # 💡 確保 Waybar 由 Systemd 管理，並掛載在 Hyprland 會話上
  programs.waybar = {
    enable = true;
    systemd = {
      enable = true;
      targets = [ "hyprland-session.target" ];
    };
  };

  # 💡 IBus 服務託管
  systemd.user.services.ibus-daemon = {
    Unit = {
      Description = "IBus Input Method Daemon";
      PartOf = [ "hyprland-session.target" ];
      After = [ "hyprland-session.target" ];
    };
    Install = { WantedBy = [ "hyprland-session.target" ]; };
    Service = {
      ExecStart = "${pkgs.ibus}/bin/ibus-daemon -drx --panel disable";
      Restart = "on-failure";
    };
  };

  # 💡 網路圖示託管
  systemd.user.services.nm-applet = {
    Unit = {
      Description = "Network Manager Applet";
      PartOf = [ "hyprland-session.target" ];
      After = [ "hyprland-session.target" ];
    };
    Install = { WantedBy = [ "hyprland-session.target" ]; };
    Service = {
      ExecStart = "${pkgs.networkmanagerapplet}/bin/nm-applet --indicator";
      Restart = "on-failure";
    };
  };

  # 只有版本號留在此處
  home.stateVersion = "24.11";
}
