{ pkgs, ... }:

{
  home.packages = with pkgs; [
    fcitx5-nord
    qt6Packages.fcitx5-chinese-addons
    noto-fonts-cjk-sans
  ];

  # 1. 外觀與佈局配置 (classicui.conf)
  xdg.configFile."fcitx5/conf/classicui.conf".text = ''
    Font="Noto Sans CJK TC 18"
    MenuFont="Noto Sans CJK TC 16"
    TrayFont="Noto Sans CJK TC 14"
    
    # 💡 關鍵：設為 False 保持「橫向排列」（左右選字）
    Vertical Candidate List=False
    
    Theme=Nord-Dark
    PerScreenDPI=True
  '';

  # 2. 💡 關鍵：用代碼強制寫死「全拼 + 你的雙拼方案 + 英文」，防止重啟消失！
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

  # 3. 如果你使用的是 Rime 方案（例如小鶴雙拼、自然碼等），
  # 我們可以把 Rime 的用戶配置也鎖定在 ~/.local/share/fcitx5/rime/
  # 這樣雙拼的自定義設定也會跟著 GitHub 走！
}
