{ pkgs, ... }:

{
  home.packages = with pkgs; [
    ibus
    ibus-engines.rime
    noto-fonts-cjk-sans
  ];

  # 💡 透過 Systemd 用戶服務託管 IBus，解決 DBus 斷線與手動啟動的煩惱
  systemd.user.services.ibus-daemon = {
    description = "IBus Input Method Daemon";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    serviceConfig = {
      # -d: 進入背景, -r: 替換現有實例, -x: 支援 X11/Wayland 整合
      ExecStart = "${pkgs.ibus}/bin/ibus-daemon -drx";
      Restart = "on-failure";
      RestartSec = 2;
    };
  };
}
