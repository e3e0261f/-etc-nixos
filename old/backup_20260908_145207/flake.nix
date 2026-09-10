{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    my-rules.url = "github:e3e0261f/GEoIP-GEoSITE";
    my-rules.flake = false;

    # 1. 引入 Home Manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # 如果以後有真正的 cool-config 再打開這裡
    # cool-config.url = "github:super-hacker/cool-hyprland"; 
  };
  # /etc/nixos/flake.nix
  outputs = { self, nixpkgs, home-manager, ... }@inputs: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        ./configuration.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          # 💡 這行是關鍵！它能幫你自動移走那些「礙事」的手動檔案
          home-manager.backupFileExtension = "backup"; 
          # 💡 確保這裡是 rhys
          home-manager.users.rhys = import ./modules/home.nix;
        }
      ];
    };
  };
}
