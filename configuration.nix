# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page.
{ config, pkgs, inputs, ... }:

let
  my-dae-assets = pkgs.stdenv.mkDerivation {
    name = "my-dae-assets";
    # 直接使用來自 Flake inputs 的原始碼
    src = inputs.my-rules; 
    
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/share/v2ray
      cp $src/geoip.dat $out/share/v2ray/geoip.dat
      cp $src/geosite.dat $out/share/v2ray/geosite.dat
    '';
  };

  nix-save = pkgs.writeShellScriptBin "nix-save" ''
    cd /etc/nixos
    # Flakes 必須先 git add 檔案，否則 Nix 找不到新檔案
    git add . 
    
    # 使用 --flake 指令替代傳統指令
    # .#nixos 代表「目前的資料夾」裡的「nixos」配置
    sudo nixos-rebuild switch --flake .#nixos
    
    if [ $? -eq 0 ]; then
      git commit -m "Save config (Flake): $(date '+%Y-%m-%d %H:%M:%S')"
      git push origin main
    fi
  '';
in


{


  imports = [ 

    ./hardware-configuration.nix
    ./modules/scripts.nix
    ./modules/nvim.nix

  ];



	boot.kernelPackages = pkgs.linuxPackages_zen;



  
  nix.settings = {
    # 同時下載的任務數 (根據你的 CPU 核心數設定，建議 4-8)
    max-jobs = "auto";
    
    # 每個任務開啟的並行連接數 (這就是你要的多線程加速！)
    http-connections = 50; 
    
    # 如果下載速度低於這個位元組/秒，持續一段時間就放棄 (防止卡死)
    min-free = 128000000;
  };


  # 補回這一行，讓系統環境支援 Fish 作為登入 Shell
  programs.fish.enable = true;
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

  # --- 1. 開啟內核 IP 轉發 (透明代理必備) ---
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  # 1. 啟用 dae 服務
  services.dae = {
    enable = true;
    assets = [ my-dae-assets ];
    config = ''
      global {
          allow_insecure: false
          so_mark_from_dae: 0

	  # 這裡「必須」指定你的真實網卡名稱
          # 如果你是筆電上網，通常是 wlp... 
          lan_interface: wlp8s0 
          wan_interface: auto

	  log_level: info # 把日誌等級調到 info，方便觀察

	  # 確保這幾項開啟，這能讓 dae 自動修改內核參數
          auto_config_kernel_parameter: true
          tproxy_port: 7890
          tproxy_port_protect: true

      }

      subscription {
          my_sub: 'https://links.rockey-repo.org/s/nXOEvhE6wHJWwSqc'
      }

      dns {
        upstream {
          smartdns: 'udp://127.0.0.1:5335'
          googledns: 'tcp+udp://dns.google:53'
          alidns: 'udp://dns.alidns.com:53'
        }
        routing {
          request {
            qname(geosite:cn) -> alidns
            fallback: alidns
          }
        }
      }

      group {
          proxy {
              policy: min_moving_avg
              filter: subtag(my_sub) && name(keyword: '新北')
          }
          sg {
              policy: min_moving_avg
              filter: subtag(my_sub) && name(keyword: 'HK')
          }
      }

      routing {
          pname(smartdns) && l4proto(udp) && dport(5335) -> direct
          pname(NetworkManager) -> direct
	  pname(dae) -> direct
          dip(224.0.0.0/3, 'ff00::/8') -> direct
          dscp(4) -> direct
          dip(geoip:private) -> direct
          
          domain(geosite:openai) -> proxy
          domain(geosite:apple@cn) -> direct
          # --- [ 第一步：確保下載走直連 ] ---
          # steam@cn 包含了大陸的遊戲下載伺服器
          domain(geosite:steam@cn) -> direct
          
          # 這裡可以加入一些常見的遊戲下載標籤
          domain(geosite:category-games@cn) -> direct

          # --- [ 第二步：確保商店與社區走代理 ] ---
          # geosite:steam 標籤通常包含了 steamcommunity.com 和 steampowered.com
          # 因為它在 steam@cn 之後，所以下載流量不會被它截獲
          domain(geosite:steam) -> proxy

          # --- [ 第三步：常規大陸流量直連 ] ---
          domain(geosite:cn) -> direct
          dip(geoip:cn) -> direct

          ### 修正後的 Telegram 規則 ###
          domain(geosite:telegram) -> proxy 

          domain(geosite:tencent) -> direct
          domain(geosite:github) -> proxy
          domain(geosite:docker) -> proxy
          
          domain(geosite: category-games@cn) -> direct
          domain(suffix: miwifi.com) -> direct(must)
          domain(suffix: cdn.pandora.xiaomi.com) -> direct(must)
          domain(suffix: tv.global.mi.com) -> direct(must)

          l4proto(udp) && dport(443) -> block
          domain(geosite:geolocation-!cn) -> proxy
          domain(geosite:china-list) -> direct

          fallback: proxy
      }
    '';
  };

  
  # SmartDNS 本地解析服务器
  services.smartdns = {
    enable = true;
    # 所有的配置都寫在 settings 裡面
    settings = {
      # 綁定埠
      bind = "127.0.0.1:5335";
      
      # 快取設定
      cache-size = 4096;
      prefetch-domain = "yes";
      serve-expired = "yes";

      # 上游伺服器列表 (用清單方式列出)
      # 注意：不要在字串裡面加 -comment，SmartDNS 不支援這種寫法
      server = [
        "8.8.8.8"
        "1.1.1.1"
        "8.8.4.4"
        "1.0.0.1"
        "114.114.114.114"
        "223.5.5.5"
      ];
      
      # 如果你有更進階的設定（例如 TCP 查詢、DoH 等），也直接寫在這裡
      # 例如：
      # server-tcp = [ "8.8.8.8" ];
    };
  };

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
  networking.networkmanager.enable = true;

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
  };


  # fcitx5
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.waylandFrontend = true; # 強烈建議加上這行，對 Wayland 支援更好
    fcitx5.addons = with pkgs; [ fcitx5-gtk qt6Packages.fcitx5-chinese-addons ];
  };

  # 自動啟動 fcitx5
  systemd.user.services.fcitx5-daemon = {
    description = "Fcitx5 input method editor";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.fcitx5}/bin/fcitx5";
      Restart = "on-failure";
    };
  };

  # 字體
  fonts.packages = with pkgs; [
    font-awesome_4
    noto-fonts-cjk-sans
    noto-fonts-color-emoji  # 👈 將 noto-fonts-emoji 改成這個
  ];

  # --- 4. 桌面環境與圖形介面 ---
  # 同時保留 GNOME (穩定) 與 Hyprland (美觀)
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    # 針對 Hyprland 的配置
    config.common.default = "*"; 
  };

  programs.waybar.enable = true;
  services.hypridle.enable = true;
  programs.hyprlock.enable = true;

  # 音效設定 (Pipewire)
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

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
    extraGroups = [ "networkmanager" "wheel" "storage" ];
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
    # 終端機與基礎工具
    vim neovim git wget curl unzip
    alacritty kitty fastfetch tree
    fd ripgrep repgrep ipgrep
    procps toybox lvm2 

    # 自定义工具
    nix-save

    # 開發工具
    cargo rustc devbox glib
    gcc gnumake libtool       # 備用，有些編譯會用到
    
    # 網路與代理
    aria2 axel bind
    # clashtui          # 如果編譯報錯，請先註解掉，部分版本名稱可能不同
    dae smartdns
    
    # 圖形化應用程式
    vscodium chromium spotify
    keepassxc discord
    polkit_gnome
    crow-translate
    gimagereader
    tesseract
    # Wayland 截图支持（如需要）
    grim
    slurp
    wl-clipboard
    translate-shell



    # KDE 應用程式 (修正這裡)
    kdePackages.ark
    kdePackages.dolphin
    
    # Hrprland 组件 
    fuzzel           # 👈 你說的 F 開頭啟動器
    waybar           # 狀態欄
    mako             # 通知
    # 文件管理器 (Thunar 及其配件)
    thunar
    thunar-volman
    thunar-archive-plugin

    # 你自訂的 FHS 環境
    (let base = pkgs.appimageTools.defaultFhsEnvArgs; in
      pkgs.buildFHSEnv (base // {
        name = "fhs";
        targetPkgs = pkgs: (base.targetPkgs pkgs) ++ (with pkgs; [
          pkg-config
          ncurses
        ]);
        profile = "export FHS=1";
        runScript = "bash";
        extraOutputsToInstall = ["dev"];
      })
    )
  ];

  # --- 7. 系統版本 ---
  # 除非重大升級，否則不要改動此值
  system.stateVersion = "24.11"; # 請確認你目前的版本，通常是 24.11
}
