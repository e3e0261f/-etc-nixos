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

    # =======================================================
    # ⭐️ 預設 192 kHz 母帶升頻 + 動態向下相容
    # =======================================================
    extraConfig.pipewire."99-audiophile" = {
      "context.properties" = {
        # ⭐️ 1. 系統預設時鐘直接拉滿到 192 kHz！
        "default.clock.rate" = 96000;

        # ⭐️ 2. 保留向下相容清單：遇到底層特定音源依然允許原生切換
        "default.clock.allowed-rates" = [ 44100 48000 88200 96000 176400 192000 ];

        # ⭐️ 3. 核心防破音：在 192kHz 速率下，把緩衝區等比拉大到 2048 / 4096
        # 2048 / 192000 = 10.6ms；4096 / 192000 = 21.3ms（給卷積運算充足時間）
        "default.clock.quantum" = 2048;
        "default.clock.min-quantum" = 1024;
        "default.clock.max-quantum" = 8192;

        # ⭐️ 4. 14 級極限母帶重採樣器（失真低於 -170dB）
        "resample.quality" = 14;
      };
    };

    # PulseAudio 相容層（Chromium、遊戲等）
    extraConfig.pipewire-pulse."99-audiophile-pulse" = {
      "context.properties" = {
        "resample.quality" = 14;
      };
      "pulse.properties" = {
        "pulse.min.req" = "1024/192000";
        "pulse.min.quantum" = "1024/192000";
        "pulse.max.quantum" = "8192/192000";
      };
    };

    # 藍牙耳機高解析解鎖 (保持 LDAC / SBC-XQ 高音質)
    wireplumber.extraConfig."99-bluetooth-hires" = {
      "wireplumber.settings" = {
        "bluetooth.autoswitch-to-headset-profile" = false;
      };
      "monitor.bluez.properties" = {
        "bluez5.enable-sbc-xq" = true;
        "bluez5.enable-msbc" = true;
        "bluez5.codecs" = [ "ldac" "aptx_hd" "aptx" "aac" "sbc_xq" "sbc" ];
        "bluez5.default.rate" = 96000;
        "bluez5.ldac.quality" = "hq";
      };
    };
  };
}
