{ pkgs, ... }:

{
  # 1. 設置 SSH 走 443 埠 (繞過 22 埠干擾)
  programs.ssh = {
    enable = true;
    extraConfig = ''
      Host github.com
        Hostname ssh.github.com
        Port 443
        User git
    '';
  };

  # 2. 設置 Git 個人信息與 GPG
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
