# /etc/nixos/modules/pipewire.nix
{ config, pkgs, ... }:

{
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true;

    extraConfig.pipewire."99-rog-extreme-workload" = {
      "context.properties" = {
        "default.clock.rate" = 48000;
        # 解锁 192k 顶级母带池
        "default.clock.allowed-rates" = [ 44100 48000 88200 96000 176400 192000 ];

        # ⭐️ 192 kHz 专属防爆缓冲：
        # 1024 帧在 192k 下刚好是 5.3ms；一旦后台开始编译，自动扩容至 4096 帧（21.3ms 大水库，绝对不爆音！）
        "default.clock.quantum" = 1024;
        "default.clock.min-quantum" = 1024;
        "default.clock.max-quantum" = 4096;

        # 算力拉满的最高品质重采样
        "resample.quality" = 10;
      };
    };

    extraConfig.pipewire-pulse."99-rog-extreme-pulse" = {
      "context.properties" = {
        "resample.quality" = 10;
      };
      "pulse.properties" = {
        "pulse.min.req" = "1024/48000";
        "pulse.min.quantum" = "1024/48000";
        # 允许 Pulse（GTA 5）扩容到 4096 帧防爆
        "pulse.max.quantum" = "4096/48000";
      };
    };

    wireplumber.extraConfig."10-disable-suspension" = {
      "monitor.alsa.rules" = [
        {
          matches = [ { "node.name" = "~alsa_output.*"; } ];
          actions = {
            update-props = {
              "session.suspend-timeout-seconds" = 0;
            };
          };
        }
      ];
    };
  };
}
