
# /etc/nixos/modules/apps/apps-heavy.nix
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    vscodium
    steam
    heroic
    linux-wallpaperengine
    mpvpaper
    aria2
    axel
    bind
    nemo
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
}
