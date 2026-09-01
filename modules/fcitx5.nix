
{ pkgs, ... }:

{
  # 1. 確保相關軟體包存在
  home.packages = with pkgs; [
    fcitx5-nord            # Nord 皮膚
    # 修正這裡：加上 qt6Packages. 前綴
    qt6Packages.fcitx5-chinese-addons 
    noto-fonts-cjk-sans    # 確保字體存在
  ];

  # 2. 2026 年程序員的硬核配置：直接生成設定檔
  # 解決「字體太小」的唯一正解是直接改設定檔
  xdg.configFile."fcitx5/conf/classicui.conf".text = ''
    # 候選詞字體與大小 (解決 4K 看不清的問題)
    Font="Noto Sans CJK TC 20"
    # 選單字體
    MenuFont="Noto Sans CJK TC 18"
    # 托盤字體
    TrayFont="Noto Sans CJK TC 14"
    
    # 改為 True 開啟垂直候選列表 (更符合人眼閱讀)
    Vertical Candidate List=True
    
    # 這裡是皮膚名稱 (如果你裝了 fcitx5-nord)
    Theme=Nord-Dark
    
    # 解決高分屏縮放問題
    PerScreenDPI=True
  '';

  # 3. 解決你之前提到「有些視窗不浮動」的配置（如果需要的話）
  # 這裡也可以放關於輸入法的環境變數
}
