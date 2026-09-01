{ pkgs, ... }:

{
  # 1. 必填：告知 Home Manager 你的系統版本
  home.stateVersion = "24.11"; 

  # 2. 搬運 Waybar 配置到這裡 (這裡才認識 xdg.configFile)
  programs.waybar.enable = true;
  xdg.configFile."waybar/config.jsonc".text = ''
    {
      "layer": "top",
      "position": "bottom",
      "exclusive": false,
      "modules-center": ["hyprland/workspaces", "clock", "pulseaudio"]
    }
  '';

  xdg.configFile."waybar/style.css".text = ''
    window#waybar {
        background-color: transparent;
    }
    .modules-center {
        background-color: rgba(30, 30, 46, 0.9);
        border-radius: 20px;
        padding: 2px 15px;
    }
  '';

  # 3. 把之前報錯的 Fish Proxy 函數也搬過來 (HM 版語法更優雅)
  programs.fish = {
    enable = true;
    functions = {
      proxy = ''
        if test (count $argv) -eq 0
            set -e http_proxy; set -e https_proxy; set -e all_proxy
            echo "Proxy cleared."
        else
            set -gx http_proxy http://127.0.0.1:$argv[1]
            set -gx https_proxy http://127.0.0.1:$argv[1]
            set -gx all_proxy socks5://127.0.0.1:$argv[1]
            echo "Proxy set to $argv[1]."
        end
      '';
    };
  };
}
