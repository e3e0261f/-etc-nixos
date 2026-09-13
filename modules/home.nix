{ pkgs, inputs, ... }:

{
  # 🎯 這裡成了唯一的「插線板 / 總路由」
  imports = [
    # ./fcitx-ibus.nix
    ./hyprland.nix
    # ./waybar.nix
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
    ./copyfile.nix
    ./yazi.nix
    ./alarm.nix
    ./awww.nix
    ./defaults.nix   # ⭐️ 預設軟體設定 (Chrome, Nemo, Helix)
    ./dev.nix        # ⭐️ Rust + JS 主力開發環境
    ./rhys.nix
  ];

    # 1. 强制声明 GTK 与 Qt 图标主题统一为 Papirus-Dark
  gtk = {
    enable = true;
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
  };

  # 2. 补齐 Fcitx5 自带的图标数据包，并加入 XDG 环境变量
  home.packages = with pkgs; [
    papirus-icon-theme
    adwaita-icon-theme
    hicolor-icon-theme
    fcitx5-material-color # 为 Fcitx5 提供完整的 Material 图标与配色支持
  ];

  # 3. 告诉 Qt 应用去哪里搜寻系统图标
  home.sessionVariables = {
    XDG_DATA_DIRS = "$XDG_DATA_DIRS:${pkgs.papirus-icon-theme}/share:${pkgs.adwaita-icon-theme}/share";
  };

  home.sessionVariables = {
    # 這是所有 GTK 程式 (包含你彈出的通知、輸入法設定) 的字體大小總開關
    GTK_FONT_NAME = "Noto Sans CJK TC 16";
  };

  # 在 home-manager (home.nix) 中：
  systemd.user.services.quickshell = {
    Unit = {
      Description = "QuickShell Desktop Shell";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      # 如果通过 flake 安装，填写 inputs.quickshell 或 pkgs.quickshell 的路径；也可以直接写 "qs"
      ExecStart = "${pkgs.quickshell}/bin/qs";
      Restart = "on-failure";       # 崩溃时自动重启
      RestartSec = "1s";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  # 💡 確保 Waybar 由 Systemd 管理，並掛載在 Hyprland 會話上
  # programs.waybar = {
  #   enable = true;
  #   systemd = {
  #     enable = true;
  #     targets = [ "hyprland-session.target" ];
  #   };
  # };
  #
  systemd.user.services.caelestia-shell = {
    Unit = {
      Description = "Caelestia Desktop Shell Daemon";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };

    Service = {
      # 填入可执行文件名称
      ExecStart = "${inputs.caelestia-shell.packages.${pkgs.system}.default}/bin/caelestia-shell";
      Restart = "on-failure";
      RestartSec = "1s";
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
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
