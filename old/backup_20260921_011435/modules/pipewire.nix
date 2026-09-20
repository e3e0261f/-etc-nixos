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
        "default.clock.quantum" = 128;
        "default.clock.min-quantum" = 64;
        # 上限給予 2048 彈性，保證遇到突發編譯時安全防爆
        "default.clock.max-quantum" = 2048;

        # 頂級重採樣品質 10（信噪比 > 160dB）
        "resample.quality" = 10;
            # =======================================================
        # 🚀 PIPEWIRE 核心硬实时（RT）抢占配置
        # =======================================================
        "cpu.rt.prio" = 95;           # 赋予 PipeWire 物理层 95 的极高实时优先级
        "nice.level" = -15;          # 极其激进的 Nice 值，全面压制普通桌面进程
      };
        # 让 PipeWire 内部的所有模块和线程都强制向 RTKit 索要实时权限
      "context.modules" = [
        {
          name = "libpipewire-module-rt";
          args = {
            "nice.level" = -15;
            "rt.prio" = 95;
            # 如果你的 Linux 内核不是特制的 RT 内核（如 linuxPackages_zen 或 rt 内核），
            # 保持 rt.time.soft/hard 为默认即可，RTKit 会自动在普通内核上模拟硬实时。
          };
          flags = [ "ifexists" "nofail" ];
        }
      ];
   };

    extraConfig.pipewire-pulse."99-studio-pulse" = {
      "context.properties" = {
        "resample.quality" = 10;
      };
      "pulse.properties" = {
        "pulse.min.req" = "128/48000";
        "pulse.min.quantum" = "64/48000";
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
