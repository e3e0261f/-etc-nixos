# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page.
{ config, pkgs, inputs, ... }:

{
  imports = [ 
    ./hardware-configuration.nix
    ./modules/nix-save.nix
    ./modules/keyd.nix
    # ./modules/helix.nix
    ./modules/dae.nix
    ./modules/pipewire.nix
    # =======================================================
    # ⭐️ 軟體安裝分層控制中心（在新電腦上裝機時由上往下解封）
    # =======================================================
    ./modules/apps/apps-gui.nix    # ⭐️ 第 1 步解封：裝上瀏覽器與日常軟體
    ./modules/apps/apps-heavy.nix  # ⭐️ 第 2 步解封：裝上 Steam、VSCode 與 4K 桌布
    ./modules/apps/apps-sec.nix    # ⭐️ 第 3 步解封：後台慢慢拉取 40+ 滲透與編譯套件
    ./modules/ssh.nix
  ];

  system.nixos.tags = [ "no-luks" ];

  boot.kernelPackages = pkgs.linuxPackages_zen;
  services.xserver.videoDrivers = [ "amdgpu" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # 降低延迟的核心依赖
  security.rtkit.enable = true;

  # 启用蓝牙支持与 Bluez 守护进程
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;
  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;

  # ⭐️ 為 Chromium 啟用 Widevine DRM 模組
  nixpkgs.config.chromium.enableWideVine = true;
  # ⭐️ 讓 NixOS 完美相容並執行通用二進位程式與遊戲
  programs.nix-ld.enable = true;
  # ⭐️ 開啟遊戲全速效能調度
  programs.gamemode.enable = true;

  services.gnome.gnome-keyring.enable = true;

  boot.extraModprobeConfig = ''
    options snd_hda_intel power_save=0 power_save_controller=N
  '';

  # 啟用智慧卡支援
  services.pcscd.enable = true;
  hardware.gpgSmartcards.enable = true;

  services.udev.extraRules = ''
    # 禁用主板自带的旧华硕板载蓝牙 (Broadcom BCM20702 蓝牙 4.0)
    SUBSYSTEM=="usb", ATTRS{idVendor}=="0b05", ATTRS{idProduct}=="180a", ATTR{authorized}="0"
  '';

  # ⭐️ ✅ 启用纯内存高速无加密压缩 Swap (替换掉物理加密 Swap)
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };

  # ⭐️ 解決 Qt 軟體黑底黑字問題
  qt = {
    enable = true;
    platformTheme = "gnome";
    style = "adwaita-dark";
  };

  nix.settings = {
    max-jobs = 16;
    http-connections = 50; 
    min-free = 128000000;
    auto-optimise-store = true;
    trusted-users = [ "root" "rhys" ];
  };
  
  # ⭐️ 強制關閉 Wi-Fi 晶片省電
  networking.networkmanager.wifi.powersave = false;
  
  # 載入 BBR 核心模組
  boot.kernelModules = [ "tcp_bbr" ];

  # ⚡ 核心参数调优（加入了 NVMe 防掉盘/防卡死参数）
  boot.kernelParams = [ 
    "pcie_aspm=off"
    "vt.global_cursor_default=0"
    "pcie_ports=compat"
    "mt7925e.disable_aspm=1"
    "nvme_core.default_ps_max_latency_us=0" # ⭐️ 彻底防止 NVMe 固态高负载 I/O 超时断联
  ];

  boot.blacklistedKernelModules = [ "bcma" "b43" ];

  # 睡眠唤醒解耦
  powerManagement = {
    enable = true;
    powerDownCommands = ''
      /run/current-system/sw/bin/modprobe -r mt7925e || true
    '';
    resumeCommands = ''
      /run/current-system/sw/bin/sleep 2
      /run/current-system/sw/bin/modprobe mt7925e || true
      /run/current-system/sw/bin/systemctl restart NetworkManager
    '';
  };

  # TCP / 網路堆疊調優
  boot.kernel.sysctl = {
    "vm.swappiness" = 10;
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr";
    "net.ipv4.tcp_fastopen" = 3;
    "net.ipv4.tcp_slow_start_after_idle" = 0;
    "net.ipv4.tcp_tw_reuse" = 1;
    "net.ipv4.tcp_fin_timeout" = 15;
    "net.core.rmem_max" = 16777216;
    "net.core.wmem_max" = 16777216;
    "net.ipv4.tcp_rmem" = "4096 87380 16777216";
    "net.ipv4.tcp_wmem" = "4096 65536 16777216";
  };
  
  # 修复 Dolphin 打开方式
  environment.etc."xdg/menus/applications.menu".source = "${pkgs.kdePackages.plasma-workspace}/etc/xdg/menus/plasma-applications.menu";

  services.gnome.gcr-ssh-agent.enable = false;
  services.gvfs.enable = true; 
  services.tumbler.enable = true;

  # Git 全域設定
  programs.git = {
    enable = true;
    config = {
      user.name = "kevin lee";
      user.email = "e3e0261f@pm.me";
      user.signingkey = "31C81A9DE1AB870A8EDC3486D7C2DF9FA0283056";
      commit.gpgsign = true;
      init.defaultBranch = "main";
    };
  };

  # --- 1. 系統核心與 Nix 設定 ---
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.permittedInsecurePackages = [
    "pnpm-10.29.2"
  ];

  # Bootloader (✅ 已彻底删除原有的 boot.initrd.luks 加密依赖行)
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # --- 2. 網路與系統服務 ---
  networking.hostName = "nixos";
  networking.networkmanager = {
    enable = true;
    connectionConfig = {
      "ipv4.route-metric" = 100;
      "ipv6.route-metric" = 100;
    };
  };

  security.pam.loginLimits = [
    { domain = "@audio"; item = "rtprio"; type = "-"; value = "95"; }
    { domain = "@audio"; item = "memlock"; type = "-"; value = "unlimited"; }
    { domain = "@audio"; item = "nice"; type = "-"; value = "-19"; }
  ];

  services.udisks2.enable = true;
  security.polkit.enable = true;
  services.printing.enable = true;
  services.flatpak.enable = true;

  # --- 3. 語系與區域設定 ---
  time.timeZone = "Asia/Taipei";
  i18n.defaultLocale = "zh_TW.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "zh_TW.UTF-8";
    LC_IDENTIFICATION = "zh_TW.UTF-8";
    LC_MEASUREMENT = "zh_TW.UTF-8";
    LC_MONETARY = "zh_TW.UTF-8";
    LC_NAME = "zh_TW.UTF-8";
    LC_NUMERIC = "zh_TW.UTF-8";
    LC_PAPER = "zh_TW.UTF-8";
    LC_TELEPHONE = "zh_TW.UTF-8";
    LC_TIME = "zh_TW.UTF-8";
    LC_MESSAGES = "zh_TW.UTF-8";
  };
  i18n.supportedLocales = [
    "en_US.UTF-8/UTF-8"
    "zh_TW.UTF-8/UTF-8"
    "zh_CN.UTF-8/UTF-8"
  ];

  environment.sessionVariables = {
    XDG_DATA_DIRS = [
      "/run/current-system/sw/share"
      "/etc/profiles/per-user/rhys/share"
      "/home/rhys/.nix-profile/share"
      "/home/rhys/.local/share"
    ];
    LANGUAGE = "zh_TW:zh_CN:zh:en";
    QT_QPA_PLATFORM = "wayland;xcb";
    GDK_BACKEND = "wayland,x11,*";
    ANKI_WAYLAND = "1";
    DIRENV_LOG_FORMAT = "";
    QS_ICON_THEME = "Papirus-Dark";
  };

  # ⭐️ 字體設定（包含排版引擎預設優先級）
  fonts = {
    packages = with pkgs; [
      inter                     # 现代无衬线西文字体（开源版 Apple SF Pro）
      nerd-fonts.jetbrains-mono # 终端等宽字体
      nerd-fonts.symbols-only   # 符号字库补全
      noto-fonts-cjk-sans       # 中文支持
      noto-fonts-color-emoji    # Emoji 表情
      font-awesome              # 网页与状态栏图标
    ];
    fontconfig = {
      enable = true;
      defaultFonts = {
        sansSerif = [ "Inter" "Noto Sans CJK SC" "Noto Color Emoji" ];
        monospace = [ "JetBrainsMono Nerd Font" "Noto Sans CJK SC" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };

  # --- 4. 桌面環境與圖形介面 ---
  services.displayManager.gdm.enable = true;

  programs.hyprland = {
    enable = true;
    withUWSM = false;
    xwayland.enable = true;
  };

  environment.variables = {
    EDITOR = "hx";
    VISUAL = "hx";
  };

  # Fcitx5 輸入法
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.waylandFrontend = true;
    fcitx5.addons = with pkgs; [
      fcitx5-gtk
      fcitx5-rime
      qt6Packages.fcitx5-chinese-addons
      fcitx5-nord
      kdePackages.fcitx5-qt
    ];
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ 
      pkgs.xdg-desktop-portal-hyprland 
      pkgs.xdg-desktop-portal-xapp
    ];
    config = {
      common = {
        "org.freedesktop.impl.portal.FileChooser" = [ "xapp" "gtk" ];
      };
    };
    configPackages = [ pkgs.hyprland ];
    config.common.default = "*"; 
  };

  services.hypridle.enable = true;
  programs.hyprlock.enable = true;

  # Polkit GNOME
  systemd.user.services.polkit-gnome-authentication-agent-1 = {
    description = "polkit-gnome-authentication-agent-1";
    wantedBy = [ "graphical-session.target" ];
    wants = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
  };

  # --- 5. 使用者設定與 Shell ---
  users.users."rhys" = {
    isNormalUser = true;
    description = "Rhys";
    extraGroups = [ "networkmanager" "wheel" "storage" "video" "render" "audio" "adbusers" ];
    shell = pkgs.zsh;
  };
  programs.zsh.enable = true;

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryPackage = pkgs.pinentry-gnome3;
  };
  
  # --- 6. 軟體安裝清單 ---
  environment.systemPackages = with pkgs; [
    (discord.override {
      withOpenASAR = true;
    })
    # 1. 救磚與終端必備
    vim neovim git wget curl unzip
    procps lvm2 p7zip unrar
    polkit_gnome networkmanagerapplet
    dust pciutils scanmem alsa-utils keyd
    usbutils esptool espflash tio opensc
    mpv
    
    # 2. 桌面與視窗管理器核心組件
    hyprlauncher hyprshutdown
    hypridle hyprlock hyprpaper hyprpicker
    pamixer ddcutil brightnessctl libcava lm_sensors aubio
    libqalculate power-profiles-daemon
    material-symbols rubik cascadia-code
    qt6.qtbase
    qt6.qtimageformats
    qt6.qtdeclarative
    qt6.qtshadertools
    swappy bash fish ninja glibc libgcc
    papirus-icon-theme
    playerctl
    wireplumber
    networkmanager
    
    # 3. 基礎圖形支撐
    wl-clipboard grim slurp translate-shell
    kdePackages.ark kdePackages.dolphin kdePackages.kservice
    
    # 4. 基礎音訊管理介面
    easyeffects pavucontrol qpwgraph helvum
    
    # 5. 專屬自訂工具
    appimage-run
  ];

  # --- 7. 系統版本 ---
  system.stateVersion = "24.11";
}
