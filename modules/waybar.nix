{ pkgs, ... }:

{
  programs.waybar.enable = true;

  # 將 waybar 的配置「聲明式」地寫入系統
  # 這樣你改這裡，執行 nix-save，全系統和 GitHub 都會同步
  xdg.configFile."waybar/config.jsonc".text = ''
    {
      "layer": "top",
      "position": "bottom",
      "exclusive": false,
      "modules-center": ["hyprland/workspaces", "clock", "pulseaudio"],
      // ... 貼上你之前的 JSON 配置 ...
    }
  '';

  xdg.configFile."waybar/style.css".text = ''
    window#waybar { background: transparent; }
    /* ... 貼上你之前的 CSS 配置 ... */
  '';
}
