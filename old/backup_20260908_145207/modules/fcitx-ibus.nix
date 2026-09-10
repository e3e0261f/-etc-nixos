{ pkgs, ... }:

let
  rime-shuangpin-src = pkgs.fetchFromGitHub {
    owner = "gaboolic";
    repo = "rime-shuangpin-fuzhuma";
    rev = "master";
    hash = "sha256-hHC2k6NAnRE2cdHNE/4M/goyI3n3IMbgRxwp5Fo8CK4="; # 填入你的真實 hash
  };
in
{
  xdg.configFile."ibus/rime" = {
    source = rime-shuangpin-src;
    recursive = true;
  };

  home.packages = with pkgs; [
    noto-fonts-cjk-sans
  ];

  # 💡 關鍵修復 1：聽從 IBus 官方警告，取消 GTK/QT 變數，只保留 XMODIFIERS
  # 這樣現代 Wayland 應用會原生走 Wayland 協議，彈窗警告徹底消失！
  home.sessionVariables = {
    XMODIFIERS = "@im=ibus";
  };

  # 💡 關鍵修復 2：拿掉 --panel disable，允許托盤圖示正常生成
  systemd.user.services.ibus-daemon = {
    Unit = {
      Description = "IBus Input Method Daemon";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" "waybar.service" ]; # 等 Waybar 托盤就緒後再啟動
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };

    Service = {
      # 正常啟動 daemon，不加 --panel disable
      ExecStart = "/run/current-system/sw/bin/ibus-daemon -rxRd";
      Restart = "on-failure";
      RestartSec = 2;
    };
  };
}
