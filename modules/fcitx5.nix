{ pkgs, ... }:

let
  # 1. 自動從 GitHub 下載雙拼輔助碼方案
  rime-shuangpin-src = pkgs.fetchFromGitHub {
    owner = "gaboolic";
    repo = "rime-shuangpin-fuzhuma";
    rev = "master";
    hash = "sha256-hHC2k6NAnRE2cdHNE/4M/goyI3n3IMbgRxwp5Fo8CK4="; # 構建時依提示換成真實 hash，或沿用你剛才編譯過的
  };
in
{
  home.packages = with pkgs; [
    noto-fonts-cjk-sans
  ];

  # 2. 💡 關鍵：自動將方案檔案軟連結到 fcitx5-rime 的專屬路徑
  # recursive = true 確保目錄可寫，讓 Rime 能編譯快取
  xdg.dataFile."fcitx5/rime" = {
    source = rime-shuangpin-src;
    recursive = true;
  };

  # 3. 外觀配置：橫排選詞、大字體、Nord-Dark 皮膚
  xdg.configFile."fcitx5/conf/classicui.conf".text = ''
    Font="Noto Sans CJK TC 18"
    MenuFont="Noto Sans CJK TC 16"
    TrayFont="Noto Sans CJK TC 14"
    Vertical Candidate List=False
    Theme=Nord-Dark
    PerScreenDPI=True
  '';

  # 4. 預載設定：預設只保留「英文鍵盤」與「Rime 中文」
  xdg.configFile."fcitx5/profile".text = ''
    [Groups/0]
    Name=Default
    Default Layout=us
    Default IM=rime

    [Groups/0/Items/0]
    Name=keyboard-us

    [Groups/0/Items/1]
    Name=rime

    [GroupOrder]
    0=Default
  '';
}
