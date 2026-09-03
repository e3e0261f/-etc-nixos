{ pkgs, ... }:

let
  rime-shuangpin-src = pkgs.fetchFromGitHub {
    owner = "gaboolic";
    repo = "rime-shuangpin-fuzhuma";
    rev = "master";
    hash = "sha256-hHC2k6NAnRE2cdHNE/4M/goyI3n3IMbgRxwp5Fo8CK4="; # 第一次構建時依提示替換真實 hash
  };
in
{
  # 1. 自動將 GitHub 下載的方案檔案部署到 ~/.config/ibus/rime
  xdg.configFile."ibus/rime" = {
    source = rime-shuangpin-src;
    recursive = true; # 保持目錄可寫，允許 Rime 生成 build/ 快取
  };

  # 2. 必備中文字體支援
  home.packages = with pkgs; [
    noto-fonts-cjk-sans
  ];

  # 3. Wayland / Hyprland 輸入法環境變數
  home.sessionVariables = {
    GTK_IM_MODULE = "ibus";
    QT_IM_MODULE = "ibus";
    XMODIFIERS = "@im=ibus";
  };

  # 4. Systemd 用戶服務：隨桌面會話自動啟動 IBus
  systemd.user.services.ibus-daemon = {
    Unit = {
      Description = "IBus Input Method Daemon";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = "/run/current-system/sw/bin/ibus-daemon -drx --panel disable";
      Restart = "on-failure";
      RestartSec = 2;
    };
  };
}
