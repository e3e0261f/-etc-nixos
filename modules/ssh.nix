# /etc/nixos/ssh-server.nix
{ config, pkgs, ... }:

{
  # 只要这个文件被 imports 引用，以下配置就会生效
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = true; # 建议后续改为 false 并使用公钥
    };
  };

  networking.firewall.allowedTCPPorts = [ 22 ];
}

