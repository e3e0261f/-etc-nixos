{ pkgs, ... }:

let
  # 我們的私有規則庫 (從 flake inputs 讀取，這裡假設你在 configuration.nix 有傳入 inputs)
  # 如果這是一個獨立模組，我們通常會用參數傳遞，這裡簡化處理
  # 為了確保可用性，我們直接定義一個輕量資產獲取邏輯
  my-dae-assets = pkgs.stdenv.mkDerivation {
    name = "my-dae-assets";
    src = pkgs.fetchFromGitHub {
      owner = "e3e0261f";
      repo = "GEoIP-GEoSITE";
      rev = "main";
      hash = "sha256-RLCjV6Plxvog54vAk6w4pZtIUGk59WoolMuJDeHQQSE="; 
    };
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/share/v2ray
      cp $src/geoip.dat $out/share/v2ray/geoip.dat
      cp $src/geosite.dat $out/share/v2ray/geosite.dat
    '';
  };
in
{
  src = inputs.my-rules;
  # 1. 啟用 dae 服務
  services.dae = {
    enable = true;
    assets = [ my-dae-assets ];
    config = ''
      global {
          lan_interface: auto
          wan_interface: auto
          log_level: info
          auto_config_kernel_parameter: true
          tproxy_port: 7890
          tproxy_port_protect: true
      }
      
      subscription {
          my_sub: 'https://links.rockey-repo.org/s/nXOEvhE6wHJWwSqc'
      }

      dns {
        upstream {
          smartdns: 'udp://127.0.0.1:5335'
          googledns: 'tcp+udp://dns.google:53'
          alidns: 'udp://dns.alidns.com:53'
        }
        routing {
          request {
            qname(geosite:cn) -> alidns
            fallback: alidns
          }
        }
      }

      group {
          proxy { policy: min_moving_avg; filter: subtag(my_sub) && name(keyword: 'I') }
          sg { policy: min_moving_avg; filter: subtag(my_sub) && name(keyword: '倍') }
      }

      routing {
          pname(smartdns) && l4proto(udp) && dport(5335) -> direct
          pname(NetworkManager) -> direct
          dip(224.0.0.0/3, 'ff00::/8') -> direct
          dscp(4) -> direct
          dip(geoip:private) -> direct
          
          domain(geosite:openai) -> proxy
          domain(geosite:apple@cn) -> direct
          domain(geosite:steam@cn) -> direct
          domain(geosite:category-games@cn) -> direct
          domain(geosite:steam) -> proxy
          domain(geosite:cn) -> direct
          dip(geoip:cn) -> direct
          domain(geosite:telegram) -> proxy
          domain(geosite:tencent) -> direct
          domain(geosite:github) -> proxy
          domain(geosite:docker) -> proxy
          domain(suffix: miwifi.com) -> direct(must)
          domain(suffix: cdn.pandora.xiaomi.com) -> direct(must)
          domain(suffix: tv.global.mi.com) -> direct(must)
          domain(suffix: mega.nz) -> sg

          l4proto(udp) && dport(443) -> block
          domain(geosite:geolocation-!cn) -> proxy
          domain(geosite:cn) -> direct

          fallback: proxy
      }
    '';
  };

  # 2. 啟用 daed 面板服務
  # services.daed.enable = true;
    # 2. 💡 修正：刪除 services.daed.enable = true;
  # 改用 systemd 手動啟動 daed 二進位檔
  systemd.services.daed = {
    description = "daed dashboard";
    wantedBy = [ "multi-user.target" ];
    after = [ "dae.service" ]; # 在 dae 啟動後再啟動 daed
    serviceConfig = {
      ExecStart = "${pkgs.daed}/bin/daed run";
      Restart = "on-failure";
    };
  };
}
