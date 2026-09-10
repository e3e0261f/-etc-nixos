# /etc/nixos/modules/dae.nix
{ config, pkgs, inputs, ... }:

let
  my-dae-assets = pkgs.stdenv.mkDerivation {
    name = "my-dae-assets";
    src = inputs.my-rules; 
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/share/v2ray
      cp $src/geoip.dat $out/share/v2ray/geoip.dat
      cp $src/geosite.dat $out/share/v2ray/geosite.dat
    '';
  };
in
{
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  services.dae = {
    enable = true;
    assets = [ my-dae-assets ];
    config = ''
      global {
          allow_insecure: false
          so_mark_from_dae: 0
          lan_interface: wlp8s0 
          wan_interface: auto
          log_level: info
          auto_config_kernel_parameter: true
          tproxy_port: 7890
          tproxy_port_protect: true
      }

      subscription {
          my_sub: 'https://links.rockey-repo.org/s/nXOEvhE6wHJWwSqc'
      }

      # =======================================================
      # ⭐️ 真正的 H3 (DoH3) 頂級解析架構（純 IPv4，杜絕 IPv6 陷阱）
      # =======================================================
      dns {
        upstream {
          # # 封鎖惡意軟體
          # cf_h3e_family: 'https://security.cloudflare-dns.com/dns-query'
          # # 封鎖惡意軟體、成人內容
          # cf_h3e_sec: 'https://family.cloudflare-dns.com/dns-query'
          # cf_doh3: '1dot1dot1dot1.cloudflare-dns.com'
          cf_doh3_domains: 'https://cloudflare-dns.com/dns-query'
          # cf_doh3_ip: 'https://1.1.1.1/dns-query'
          # cf_h3_1: 'h3://1.1.1.1:443/dns-query'
          # cf_h3_2: 'h3://1.0.0.1:443/dns-query'
          # # 國外備用：Google DoH3
          # google_h3: 'h3://8.8.8.8:443/dns-query'
          # # 國內主解析：阿里 DoH3（國內直連，極速無污染）
          ali_h3: 'h3://223.5.5.5:443/dns-query'
          # cfdns: 'tcp+udp://1.1.1.1:53'
          # googledns: 'tcp+udp://8.8.8.8:53'
          # alidns: 'udp://dns.alidns.com:53'
          # 2. 海外域名交給 NextDNS，享有乾淨、無污染且能擋廣告的解析
          # nextdns: 'https://nextdns.io'

        }
        routing {
          request {
            # 國內網域走阿里 DoH3
            qname(geosite:cn) -> ali_h3
            # 國外網域由 Cloudflare DoH3 遠端解析
            fallback: cf_doh3_domains
          }
        }
      }

      # =======================================================
      # ⭐️ 核心節點池設計（嚴管 4倍/6倍 + 排除四大無效關鍵字）
      # =======================================================
      group {
          cheap {
              policy: min_moving_avg
              filter: subtag(my_sub) && !name(regex: '4倍|6倍|剩余|到期')
          }
          google_ai {
              policy: min_moving_avg
              filter: subtag(my_sub) && !name(regex: 'HK|Hong Kong|香港|广州|剩余|到期|4倍|6倍|直连')
          }
          premium_high {
              policy: min_moving_avg
              filter: subtag(my_sub) && name(regex: '4倍|6倍|TW') && !name(regex: '剩余|到期|HK')
          }
      }

      # =======================================================
      # ⭐️ 路由分流規則（順序至關重要！嚴格按邏輯排序）
      # =======================================================
      routing {
          # ⭐️ 加上 direct-curl，任何以此名稱運行的指令 100% 強制本機直連出海，絕不走代理！
          # pname(direct-curl, systemd-resolved, dnsmasq, NetworkManager, dae) -> direct(must)
          # ⭐️【第 0 級最高優先】：為國外 H3 DNS 鋪路！
          # 必須趕在 pname(dae) 之前，將 1.1.1.1 和 8.8.8.8 的 443 埠塞入代理隧道！
          # dip(1.1.1.1, 1.0.0.1) && dport(443) -> premium_high
          dip(8.8.8.8, 8.8.4.4) && dport(443) -> google_ai
          
          # ⭐️【第 1 級】：國內 H3 DNS (阿里 223.5.5.5) 強制走本機直連出海
          dip(223.5.5.5, 223.6.6.6) -> direct(must)
          domain(full: dns.alidns.com) -> direct(must)
          # domain(full:cloudflare-dns.com) -> premium_high

          # ⭐️【第 2 級】：核心進程放行（防止其他守護進程陷入死鎖）
          pname(systemd-resolved, dnsmasq, NetworkManager, dae) -> direct(must)
          dip(geoip:private) -> direct
          
          # ⭐️【第 3 級】：國內服務與遊戲直連（免除代理消耗）
          domain(geosite:apple@cn) -> direct
          domain(geosite:steam@cn) -> direct          
          domain(geosite:category-games@cn) -> direct  
          domain(geosite:cn) -> direct
          dip(geoip:cn) -> direct
          domain(geosite:tencent) -> direct
          domain(geosite:china-list) -> direct
          domain(suffix: miwifi.com) -> direct(must)
          domain(suffix: xiaomi.com) -> direct(must)
          domain(suffix: mi.com) -> direct(must)

          # ⭐️【第 4 級】：Google AI 專區（避開 HK 與廣州）
          domain(geosite:openai) -> google_ai
          domain(geosite:google) -> google_ai
          domain(suffix: aistudio.google.com) -> google_ai
          domain(suffix: google.dev) -> google_ai
          domain(suffix: ai.google.dev) -> google_ai
          domain(suffix: gemini.google.com) -> google_ai
          domain(suffix: makersuite.google.com) -> google_ai
          domain(suffix: alkalimakersuite.googleapis.com) -> google_ai
          domain(suffix: generativelanguage.googleapis.com) -> google_ai
          domain(suffix: clients6.google.com) -> google_ai

          # ⭐️【第 5 級】：大流量大數據專區（鎖死在 cheap 池，嚴禁 4倍/6倍）
          domain(geosite:youtube) -> cheap
          domain(geosite:steam) -> cheap
          domain(geosite:github) -> cheap
          domain(geosite:docker) -> cheap
          domain(geosite:telegram) -> cheap
          domain(geosite:netflix) -> cheap
          domain(geosite:bilibili@!cn) -> cheap
          # ⭐️ 解決 Veloren 遊戲與 Airshipper 下載卡死問題
          # 讓遊戲下載、登入與伺服器全部走穩定的台灣節點
          # domain(suffix: veloren.net) -> direct
          # domain(suffix: gitlab.com) -> direct
          # domain(suffix: game.nort-sun.com) -> direct
          # domain(suffix: veloren.hgxds.cn) -> direct
          # domain(suffix: yplay.velorenla.com) -> direct
          # domain(suffix: joeisthebest.mooo.com) -> direct
          # # 開源素材託管(S3 存儲)
          # domain(suffix: wasabisys.com) -> direct
          
          
          # ⭐️【第 6 級】：阻斷普通網站的 QUIC (UDP 443)
          # 注意：因為第 0 級已經把 1.1.1.1:443 挑走了，這行絕不會誤殺我們自己的 H3 DNS！
          l4proto(udp) && dport(443) -> block

          # Mega.nz 專用高速通道
          domain(suffix: mega.nz) -> premium_high

          # 終極兜底（所有其他生僻外網）
          fallback: premium_high
      }
    '';
  };
}
