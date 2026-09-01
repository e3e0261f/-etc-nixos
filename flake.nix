{
  description = "Rhys's NixOS Flake Configuration";

	# 1. 輸入：定義你的資源來自哪裡
	inputs = {
	  # 改成這個寫法，Nix 會自動下載極小的 tar.gz 壓縮包，而不是整個 3.5GB 的 Git 歷史
	  nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

	  my-rules.url = "github:e3e0261f/GEoIP-GEoSITE";
	  my-rules.flake = false;
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
