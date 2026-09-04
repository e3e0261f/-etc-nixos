{ pkgs, ... }:

{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false; 

    # 💡 使用 Home Manager 標準的 matchBlocks 結構化宣告
    settings = {
      "github.com" = {
        hostname = "ssh.github.com";
        port = 443;
        user = "git";
      };

      # 如果你希望「所有主機 (*)」預設都走 443 埠，可以把下面這段打開：
      # "*" = {
      #   port = 443;
      # };
    };
  };

  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "kevin lee";
        email = "e3e0261f@pm.me";
      };
      init.defaultBranch = "main";
      commit.gpgsign = true;
    };
    signing = {
      key = "31C81A9DE1AB870A8EDC3486D7C2DF9FA0283056";
      signByDefault = true;
    };
  };
}
