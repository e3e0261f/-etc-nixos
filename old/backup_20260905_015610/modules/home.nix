{ pkgs, ... }:

{
  # 🎯 這裡成了唯一的「插線板 / 總路由」
  imports = [
    # ./fcitx-ibus.nix
    # ./hyprland.nix
    ./waybar.nix
    ./openmega.nix
    ./kitty.nix
    ./shell.nix
    ./tools.nix
    ./helix.nix
    ./git.nix
    ./fcitx5.nix
    ./mako.nix
    ./fuzzel.nix
  ];

  # 只有版本號留在此處
  home.stateVersion = "24.11";
}
