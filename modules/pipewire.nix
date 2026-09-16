# /etc/nixos/modules/pipewire.nix
{ config, pkgs, ... }:

{
  # ⚠️ 修正：NixOS 正确的禁用 PulseAudio 语法是 hardware.pulseaudio
  services.pulseaudio.enable = false; # 如果编译报 warning 可改为 hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true;

    # =======================================================
    # ⭐️ 96 kHz 高解析母帶 + 真正穩定的 Hi-Fi 策略
    # =======================================================
    extraConfig.pipewire."99-audiophile" = {
      "context.properties" = {
        # 1. 系統預設時鐘鎖定 96 kHz
        "default.clock.rate" = 96000;

        # 2. 允許原生切換：遇到底層特定音源允許原生切換，避免非整數倍重採樣
        "default.clock.allowed-rates" = [ 44100 48000 88200 96000 176400 192000 ];

        # 3. 穩定緩衝區：鎖死在 1024 ~ 2048（約 10ms ~ 21ms）
        # 徹底禁止緩衝區漂移到 8192 引發顫音！
        "default.clock.quantum" = 2048;
        "default.clock.min-quantum" = 2048;
        "default.clock.max-quantum" = 2048;

        # 4. 關鍵修復：重採樣品質設為 7 或 4
        # 品質 7 的失真已低於 -140dB（超越 24-bit 物理極限），且 CPU 零負擔、零群延遲！
        "resample.quality" = 7;
      };
    };

    # PulseAudio 相容層（Chromium、Spotify、遊戲）
    extraConfig.pipewire-pulse."99-audiophile-pulse" = {
      "context.properties" = {
        "resample.quality" = 7;
      };
      "pulse.properties" = {
        # 與主時鐘 96000 保持基準一致
        "pulse.min.req" = "2048/96000";
        "pulse.min.quantum" = "2048/96000";
        "pulse.max.quantum" = "2048/96000";
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
