# /etc/nixos/modules/git.nix
{ pkgs, ... }:

{
  # ⭐️ SSH 模組：遇到 github.com 自動走 443 埠（穿透防火牆）
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    matchBlocks = {
      "github.com" = {
        hostname = "ssh.github.com";
        port = 443;
        user = "git";
      };
    };
  };

  # ⭐️ Git 模組：配置簽名、預設分支，以及全自動把 HTTPS 轉向 SSH (GPG)
  programs.git = {
    enable = true;
    userName = "kevin lee";
    userEmail = "e3e0261f@pm.me";

    signing = {
      key = "31C81A9DE1AB870A8EDC3486D7C2DF9FA0283056";
      signByDefault = true;
    };

    extraConfig = {
      init.defaultBranch = "main";
      commit.gpgsign = true;

      # ⭐️ 核心宣告式規則：全域將所有 https://github.com/ 自動替換為 SSH 協議（走 GPG 密鑰握手）
      "url \"git@github.com:\"".insteadOf = "https://github.com/";
    };
  };
}
