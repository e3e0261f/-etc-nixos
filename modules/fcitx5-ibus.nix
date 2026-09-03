{ pkgs, ... }:

{
  home.packages = with pkgs; [
    ibus
    ibus-engines.rime
    noto-fonts-cjk-sans
  ];

  # 1. 設置 Wayland 輸入法環境變數
  home.sessionVariables = {
    GTK_IM_MODULE = "ibus";
    QT_IM_MODULE = "ibus";
    XMODIFIERS = "@im=ibus";
  };

  # 2. 💡 Home Manager 標準的 Systemd 語法（使用 Unit, Service, Install 大寫區塊）
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
      ExecStart = "${pkgs.ibus}/bin/ibus-daemon -drx";
      Restart = "on-failure";
      RestartSec = 2;
    };
  };
}
