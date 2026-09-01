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

  outputs = { self, nixpkgs, home-manager, ... }@inputs: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        # --- 列表項目 1: 檔案路徑 ---
        ./configuration.nix

        # --- 列表項目 2: 模組路徑 (注意：沒有分號) ---
        home-manager.nixosModules.home-manager

        # --- 列表項目 3: 配置區塊 (大括號內部每一行都要分號) ---
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = { inherit inputs; };
          home-manager.backupFileExtension = "backup";
          home-manager.users.rhys = import ./modules/home.nix;
        }
      ];
    };
  };
}
