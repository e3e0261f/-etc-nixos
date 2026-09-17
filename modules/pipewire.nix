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

    # =======================================================
    # 🎙️ 錄音棚極限低延遲發燒架構（Studio Extreme 256）
    # =======================================================
    extraConfig.pipewire."99-studio-extreme" = {
      "context.properties" = {
        "default.clock.rate" = 48000;
        "default.clock.allowed-rates" = [ 44100 48000 88200 96000 176400 192000 ];

        # ⭐️ 錄音棚黃金緩衝區：256 幀（48k 下 5.3ms，物理級無感耳返！）
        "default.clock.quantum" = 256;
        "default.clock.min-quantum" = 256;
        # 上限給予 2048 彈性，保證遇到突發編譯時安全防爆
        "default.clock.max-quantum" = 2048;

        # 頂級重採樣品質 10（信噪比 > 160dB）
        "resample.quality" = 10;
      };
    };

    extraConfig.pipewire-pulse."99-studio-pulse" = {
      "context.properties" = {
        "resample.quality" = 10;
      };
      "pulse.properties" = {
        "pulse.min.req" = "256/48000";
        "pulse.min.quantum" = "256/48000";
        "pulse.max.quantum" = "2048/48000";
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
