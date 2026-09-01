{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    my-rules.url = "github:e3e0261f/GEoIP-GEoSITE";
    my-rules.flake = false;

    # 1. 引入 Home Manager
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs"; # 讓它跟隨系統套件版本
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        ./configuration.nix
        # 2. 載入 Home Manager 模組
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = { inherit inputs; };
          # 如果檔案衝突，自動把舊檔案重新命名為 filename.backup
          home-manager.backupFileExtension = "backup";
          # 3. 指定你的用戶 (rhys) 的配置
          home-manager.users.rhys = import ./modules/home.nix;
        }
      ];
    };
  };
}
