{
  description = "Rhys's NixOS Flake Configuration";

  # 1. 輸入：定義你的資源來自哪裡
  inputs = {
    # 官方 NixOS 套件源 (使用你目前的 Unstable 分支)
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    
    # 你的個人規則庫 (現在可以直接作為一個輸入！)
    my-rules.url = "github:e3e0261f/GEoIP-GEoSITE";
    my-rules.flake = false; # 因為你的庫不是一個 Flake，所以設為 false
  };

  # 2. 輸出：定義如何構建你的系統
  outputs = { self, nixpkgs, my-rules, ... }@inputs: {
    # 'nixos' 是你的主機名稱 (hostname)
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; }; # 把 inputs 傳遞給 configuration.nix
      modules = [
        ./configuration.nix # 讀取原本的設定檔
      ];
    };
  };
}
