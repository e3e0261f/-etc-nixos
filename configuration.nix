# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page.
{ config, pkgs, inputs, ... }:

{


  imports = [ 
    ./hardware-configuration.nix
    ./modules/nix-save.nix
    ./modules/keyd.nix
    # ./modules/helix.nix
    # ./modules/dae-cloudflare.nix
    ./modules/dae.nix
    ./modules/pipewire.nix
    # =======================================================
    # ⭐️ 軟體安裝分層控制中心（在新電腦上裝機時由上往下解封）
    # =======================================================
    ./modules/apps/apps-gui.nix    # ⭐️ 第 1 步解封：裝上瀏覽器與日常軟體
    ./modules/apps/apps-heavy.nix  # ⭐️ 第 2 步解封：裝上 Steam、VSCode 與 4K 桌布
    ./modules/apps/apps-sec.nix    # ⭐️ 第 3 步解封：後台慢慢拉取 40+ 滲透與編譯套件
  ];


  system.nixos.tags = [ "UPDATE-NOT-PROXY" ];

	boot.kernelPackages = pkgs.linuxPackages_zen;
	# boot.initrd.kernelModules = [ "amdgpu" ];
  services.xserver.videoDrivers = [ "amdgpu" ];

    hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  # 必须写在 configuration.nix 的大括号内
  security.rtkit.enable = true; # 必须开启！EasyEffects 和 Pipewire 降低延迟的核心依赖
    # 启用蓝牙支持与 Bluez 守护进程
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true; # 开机自动激活蓝牙
  services.blueman.enable = true;          # 提供蓝牙图表管理工具

  # ⭐️ 為 Chromium 啟用 Widevine DRM 模組（支援 Spotify、Netflix 網頁播放）
  nixpkgs.config.chromium.enableWideVine = true;
  # ⭐️ 讓 NixOS 完美相容並執行所有通用 Linux 下載的二進位程式與遊戲
  programs.nix-ld.enable = true;
  # ⭐️ 開啟遊戲全速效能調度守護程序
  programs.gamemode.enable = true;

  # ⭐️ 解決 Dolphin 等 Qt 軟體黑底黑字問題
  qt = {
    enable = true;
    platformTheme = "gnome";
    style = "adwaita-dark";
  };

  # ⭐️ 允許 wheel 組用戶免輸入密碼直接掛載內接硬碟與 USB
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if ((action.id == "org.freedesktop.udisks2.filesystem-mount-system" ||
           action.id == "org.freedesktop.udisks2.filesystem-mount") &&
          subject.isInGroup("wheel")) {
        return polkit.Result.YES;
      }
    });
  '';

  nix.settings = {
    # 同時下載的任務數 (根據你的 CPU 核心數設定，建議 4-8) 1
    max-jobs = 16;
    
    # 每個任務開啟的並行連接數 (這就是你要的多線程加速！)
    http-connections = 50; 
    
    # 如果下載速度低於這個位元組/秒，持續一段時間就放棄 (防止卡死)
    min-free = 128000000;
    
    # ⭐️ 核心黑科技：開啟二進位快取信任與替換
    auto-optimise-store = true; # 自動清理 /nix/store 中的重複檔案，極大節省硬碟空間！
    
    # 信任的額外快取服務器（讓 Nix 自動下載別人編譯好的現成包）
    trusted-users = [ "root" "rhys" ];
  };
  
  # ⭐️ 強制關閉 Wi-Fi 晶片省電，維持網卡隨時全速發射
  networking.networkmanager.wifi.powersave = false;
  
  # 1. 載入 BBR 核心模組
  boot.kernelModules = [ "tcp_bbr" ];
    # ⚡ 阻止 PCIe 链路进入主动电源管理 (ASPM) 省电状态，彻底根治 PCIe WiFi 延迟抖动与断流
  boot.kernelParams = [ 
    "pcie_aspm=off"
    "vt.global_cursor_default=0" 
  ];


  # 2. 核心 TCP / 網路堆疊終極調優
  boot.kernel.sysctl = {

    # 只有在記憶體快用盡時才動用硬碟 Swap，平時完全利用高速 RAM
    "vm.swappiness" = 10;
    
    # ⭐️ 啟用 BBR + FQ 排隊調度演算法
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr";

    # ⭐️ 啟用 TCP Fast Open (TFO)：握手時直接附帶資料，省去 1 個 RTT 往返延遲
    "net.ipv4.tcp_fastopen" = 3;

    # ⭐️ 關閉「閒置後慢啟動」：
    # 瀏覽網頁時，如果停在某個頁面幾秒沒點，TCP 不會降低發送速度，點下一個連結依然保持滿速！
    "net.ipv4.tcp_slow_start_after_idle" = 0;

    # 提高 TIME_WAIT 連接的重複利用率，高並發網頁瀏覽更順暢
    "net.ipv4.tcp_tw_reuse" = 1;
    "net.ipv4.tcp_fin_timeout" = 15;

    # 擴大網路最大緩衝區（現代百兆/千兆寬頻必備）
    "net.core.rmem_max" = 16777216;
    "net.core.wmem_max" = 16777216;
    "net.ipv4.tcp_rmem" = "4096 87380 16777216";
    "net.ipv4.tcp_wmem" = "4096 65536 16777216";
  };
  
  
  # 補回這一行，讓系統環境支援 Fish 作為登入 Shell
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      # ⭐️ copyfile 專屬補全 (啟動時強制載入)
      complete -c copyfile -s u -l uri -d "使用 text/uri-list 格式 (瀏覽器/Discord)"
      complete -c copyfile -s h -l help -d "顯示幫助訊息"
    '';
  };

  # 修复 Dolphin 非 KDE 环境下找不到打开方式/系统列表的 Bug
  environment.etc."xdg/menus/applications.menu".source = "${pkgs.kdePackages.plasma-workspace}/etc/xdg/menus/plasma-applications.menu";


  programs.fish.shellInit = ''
    export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
  '';
  # Fish 代理proxy命令循环
  environment.etc."fish/functions/proxy.fish".text = ''
    function proxy
        if test (count $argv) -eq 0
            # 無參數：清理
            set -e http_proxy
            set -e https_proxy
            set -e all_proxy
            echo "Proxy environment cleared. Welcome back to nature."
        else
            # 有參數：設定代理
            set -gx http_proxy http://127.0.0.1:$argv[1]
            set -gx https_proxy http://127.0.0.1:$argv[1]
            set -gx all_proxy socks5://127.0.0.1:$argv[1]
            echo "Proxy set to port $argv[1]. Ready to fly."
        end
    end
  '';

  # 1. 關閉 GNOME 內建的 SSH 代理，避免與 GnuPG 衝突
  services.gnome.gcr-ssh-agent.enable = false;
    # 確保硬碟掛載功能正常 (Thunar 必備)
  services.gvfs.enable = true; 
  services.tumbler.enable = true;

  # 配置 Git 全域設定
  programs.git = {
    enable = true;
    config = {
      user.name = "kevin lee";
      user.email = "e3e0261f@pm.me";
      # 使用你的 GPG Key ID
      user.signingkey = "31C81A9DE1AB870A8EDC3486D7C2DF9FA0283056";
      # 開啟自動簽名 commit，這樣 GitHub 會顯示 "Verified"
      commit.gpgsign = true;
      # 解決 init 時的預設分支問題
      init.defaultBranch = "main";
    };
  };

  # --- 1. 系統核心與 Nix 設定 ---
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.permittedInsecurePackages = [
    "pnpm-10.29.2"
  ];

  # Bootloader & LUKS
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.luks.devices."luks-911433c6-a309-4bb3-9ebb-109b6fedcf6b".device = "/dev/disk/by-uuid/911433c6-a309-4bb3-9ebb-109b6fedcf6b";

  # --- 2. 網路與系統服務 ---
  networking.hostName = "nixos";
  networking.networkmanager = {
    enable = true;
    # 👈 修正为官方标准的选项名称
    connectionConfig = {
      "ipv4.route-metric" = 100;
      "ipv6.route-metric" = 100;
    };
  };


  services.udisks2.enable = true;     # 硬碟自動掛載
  security.polkit.enable = true;      # 權限認證核心
  services.printing.enable = true;    # 列印服務
  services.flatpak.enable = true;     # 啟用 Flatpak 支援

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
    LC_MESSAGES = "zh_TW.UTF-8";  # ⭐️ 核心 1：強制所有軟體選單和介面文字使用中文！
  };
    # 确保 EasyEffects 所需的 UI 翻译支持已包含在系统支持的语言包中
  i18n.supportedLocales = [
    "en_US.UTF-8/UTF-8"
    "zh_TW.UTF-8/UTF-8"
    "zh_CN.UTF-8/UTF-8"
  ];
    # ⭐️ LANGUAGE 是環境變數，要獨立寫在外面（注意結尾都有分號）！
  environment.sessionVariables = {
    # 確保 KDE 軟體能精準找到 NixOS 的所有 .desktop 啟動項
    XDG_DATA_DIRS = [
      "/run/current-system/sw/share"
      "/etc/profiles/per-user/rhys/share"
      "/home/rhys/.nix-profile/share"
      "/home/rhys/.local/share"
    ];
    LANGUAGE = "zh_TW:zh_CN:zh:en";
    # ⭐️ 补上这三行，强制所有 Qt/GTK 应用走原生 Wayland，并修复 Dolphin 在独立 WM 下的缩放和主题
    QT_QPA_PLATFORM = "wayland;xcb";
    GDK_BACKEND = "wayland,x11,*";
    ANKI_WAYLAND = "1";
    DIRENV_LOG_FORMAT = ""; # 干净终端
    # ⭐️ 强力将 Chromium 变黑：启用原生深色主题，并强制将所有普通网页转换为黑暗模式
    CHROMIUM_FLAGS = [
      "--enable-features=WebUIDarkMode,Vulkan,DefaultANGLEVulkan"
      "--use-angle=vulkan"
      "--enable-gpu-rasterization"
      "--enable-zero-copy"
      "--ignore-gpu-blocklist"
      "--force-dark-mode"
      "--enable-blink-features=ForceDarkMode"
    ];
  };

  
  # 字體
  fonts.packages = with pkgs; [
    font-awesome_4
    noto-fonts-cjk-sans
    noto-fonts-color-emoji  # 👈 將 noto-fonts-emoji 改成這個
    # 2. 💡 關鍵：把上面那 10 個倉庫的全部符號一網打盡！
    nerd-fonts.jetbrains-mono # 自帶全套開發者圖示的等寬字體
    nerd-fonts.symbols-only   # 獨立的「純圖示符號字庫」(補全所有缺失符號)
    font-awesome              # 官方 Font Awesome 6
  ];

  # --- 4. 桌面環境與圖形介面 ---
  # 同時保留 GNOME (穩定) 與 Hyprland (美觀)
  services.displayManager.gdm.enable = true;
  # services.desktopManager.gnome.enable = true;

  programs.hyprland = {
    enable = true;
    withUWSM = false;
    xwayland.enable = true;
  };

  environment.variables = {
    EDITOR = "hx";
    VISUAL = "hx";
  };

  # 💡 啟用系統級 Fcitx5，並打包 Rime 引擎與 Nord 皮膚
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.waylandFrontend = true; # 👈 原生 Wayland 支持，永不報錯
    fcitx5.addons = with pkgs; [
      fcitx5-gtk
      fcitx5-rime                      # 👈 核心：Rime 引擎
      qt6Packages.fcitx5-chinese-addons
      fcitx5-nord                      # 👈 Nord 深色皮膚
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
        # 強制讓檔案選擇對話框使用 xapp 或者是 gtk 
        "org.freedesktop.impl.portal.FileChooser" = [ "xapp" "gtk" ];
      };
    };
    configPackages = [ pkgs.hyprland ]; # 👈 确保 Portal 能准确读取到 Hyprland 的特定行为配置
    config.common.default = "*"; 
  };


  programs.waybar.enable = true;
  services.hypridle.enable = true;
  programs.hyprlock.enable = true;

  # # 音效設定 (Pipewire)
  # services.pulseaudio.enable = false;
  # security.rtkit.enable = true;
  # services.pipewire = {
  #   enable = true;
  #   alsa.enable = true;
  #   alsa.support32Bit = true;
  #   pulse.enable = true;
  # };

  # 解決「無法請求認證」的問題：在 Hyprland 下啟動 Polkit GNOME
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
    extraGroups = [ "networkmanager" "wheel" "storage" "video" "render" ];
    shell = pkgs.fish;
  };


    # 2. 確保 GnuPG Agent 負責 SSH
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true; # 讓 GPG 密鑰也能當 SSH 密鑰用
    pinentryPackage = pkgs.pinentry-gnome3;
  };
  
  # --- 6. 軟體安裝清單 (整合你之前 nix profile 的所有軟體) ---
  environment.systemPackages = with pkgs; [
        # 1. 救磚與終端必備
    vim neovim git wget curl unzip
    procps lvm2 p7zip unrar
    polkit_gnome networkmanagerapplet
    dust
    
    # 2. 桌面與視窗管理器核心組件 (沒有它們進不去桌面)
    fuzzel waybar mako
    hyprlauncher hyprshutdown
    hypridle hyprlock hyprpaper hyprpicker
    
    # 3. 基礎圖形支撐
    wl-clipboard grim slurp translate-shell
    kdePackages.ark kdePackages.dolphin kdePackages.kservice
    
    # 4. 基礎音訊管理介面
    easyeffects pavucontrol qpwgraph helvum
    
    # 5. 專屬自訂工具
    appimage-run
    ];
    
  # 他在代碼裡定義的開關，你直接拿來用
  #services.cool-hyprland.enable = true;
  #services.cool-hyprland.theme = "neon-purple";
  # --- 7. 系統版本 ---
  # 除非重大升級，否則不要改動此值
  system.stateVersion = "24.11";
}
