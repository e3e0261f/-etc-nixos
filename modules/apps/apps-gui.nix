
# /etc/nixos/modules/apps/apps-gui.nix
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    google-chrome       # 或 chromium
    spotify
    discord
    keepassxc
    vlc
    mplayer
    crow-translate
    gimagereader
    tesseract
    waypaper
    loupe
  ];
}
