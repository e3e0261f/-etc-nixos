{
  description = "CyberArch Hyprland theme/config (flake)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    home-manager.url = "github:nix-community/home-manager";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, home-manager, flake-utils, ... }:
    let
      # per-system outputs
      perSystem = flake-utils.lib.eachDefaultSystem (system:
        let
          pkgs = import nixpkgs { inherit system; };
          lib  = pkgs.lib;
          here = ./.;

          # Build the home-manager configuration for this system/user
          hm = home-manager.lib.homeManagerConfiguration {
            inherit pkgs;

            modules = [
              ({ config, pkgs, ... }: {
                home.file.".config/hypr/".source = "${here}/config";
                home.activation.copy-cyberarch-assets = lib.mkAfter ''
                  mkdir -p $HOME/.local/share/hyprland/themes/cyberarch
                  cp -r ${here}/assets/* $HOME/.local/share/hyprland/themes/cyberarch/ || true
                  cp -r ${here}/scripts $HOME/.local/share/hyprland/themes/cyberarch/scripts || true
                '';
              })
            ];
          };
        in {
          packages = {
            themeInstaller = pkgs.stdenv.mkDerivation {
              pname = "cyberarch-hypr-theme";
              version = "0.1";
              src = here;
              phases = [ "installPhase" ];
              installPhase = ''
                outdir=$out/share/hyprland/themes/cyberarch
                mkdir -p "$out/share/hyprland/themes/cyberarch"
                cp -r ${here}/assets/* "$out/share/hyprland/themes/cyberarch/" || true
                cp -r ${here}/scripts "$out/share/hyprland/themes/cyberarch/scripts" || true
                cp -r ${here}/config "$out/share/hyprland/themes/cyberarch/config" || true
                echo "Installed theme assets to $out/share/hyprland/themes/cyberarch"
              '';
            };

            # export activation package so home-manager CLI can find it
            homeConfigurations = {
              rhys = hm.activationPackage;
            };
          };

          # defaultPackage for `nix run .` on this system
          defaultPackage = self.packages.${system}.themeInstaller;
        });

      # top-level homeConfigurations: pick one system's hm and expose its full config object
      # Here we construct a top-level homeConfigurations.rhys using x86_64-linux
      topLevelHome = let
        pkgs_x86 = import nixpkgs { system = "x86_64-linux"; };
        lib_x86 = pkgs_x86.lib;
        here = ./.;
        hm_x86 = home-manager.lib.homeManagerConfiguration {
          inherit pkgs_x86;
          modules = [
            ({ config, pkgs, ... }: {
              home.file.".config/hypr/".source = "${here}/config";
              home.activation.copy-cyberarch-assets = lib_x86.mkAfter ''
                mkdir -p $HOME/.local/share/hyprland/themes/cyberarch
                cp -r ${here}/assets/* $HOME/.local/share/hyprland/themes/cyberarch/ || true
                cp -r ${here}/scripts $HOME/.local/share/hyprland/themes/cyberarch/scripts || true
              '';
            })
          ];
        };
      in hm_x86;
    in
    # Merge per-system outputs with a top-level homeConfigurations attribute
    (perSystem // {
      homeConfigurations = {
        rhys = topLevelHome;
      };
    });
}
