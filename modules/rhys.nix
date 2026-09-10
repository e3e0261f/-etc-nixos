# /etc/nixos/modules/rhys.nix
{ pkgs, ... }:

let
  rhysCommand = pkgs.writeShellScriptBin "rhys" ''
    #!/usr/bin/env bash

    # ANSI 顏色定義
    C_CYAN="\033[1;36m"
    C_GREEN="\033[1;32m"
    C_YELLOW="\033[1;33m"
    C_BLUE="\033[1;34m"
    C_PURPLE="\033[1;35m"
    C_RED="\033[1;31m"
    C_WHITE="\033[1;37m"
    C_GRAY="\033[0;90m"
    C_BOLD="\033[1m"
    C_RESET="\033[0m"

    show_header() {
      echo -e "''${C_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━''${C_RESET}"
      echo -e "  🚀 ''${C_WHITE}RHYS · NIXOS 專屬全系統極客百科與指揮中心''${C_RESET} ''${C_GRAY}(v158 Milestone)''${C_RESET}"
      echo -e "''${C_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━''${C_RESET}"
    }

    # 1. 檔案與模組分布地圖 (rhys files / rhys -f)
    show_files() {
      show_header
      echo -e "\n''${C_PURPLE}📂 【系統核心與模組架構地圖 (/etc/nixos/)】''${C_RESET}"
      echo -e "  ''${C_WHITE}/etc/nixos/''${C_RESET}"
      echo -e "  ''${C_GRAY}├──''${C_RESET} ''${C_GREEN}configuration.nix''${C_RESET}    : 系統第 0 級基礎設施 (Zen內核, AMD顯卡, BBR+FQ, Polkit免密, 禁用IPv6)"
      echo -e "  ''${C_GRAY}├──''${C_RESET} ''${C_GREEN}hardware-configuration.nix''${C_RESET}: 磁碟分割區 (XFS), LUKS 加密 UUID, systemd-boot"
      echo -e "  ''${C_GRAY}├──''${C_RESET} ''${C_GREEN}flake.nix / flake.lock''${C_RESET}  : Flakes 宣告式根入口與依賴鎖"
      echo -e "  ''${C_GRAY}└──''${C_RESET} ''${C_WHITE}modules/''${C_RESET}               : 模組化子目錄 (責任分離)"
      echo -e "      ''${C_GRAY}├──''${C_RESET} ''${C_BLUE}dae-h3.nix''${C_RESET}          : eBPF 內核透明代理 (DoH3, cheap/google_ai/premium三級節點池)"
      echo -e "      ''${C_GRAY}├──''${C_RESET} ''${C_BLUE}pipewire.nix''${C_RESET}        : 192kHz 母帶級音訊 (32-bit浮點, Quantum 2048防破音, LDAC 990k)"
      echo -e "      ''${C_GRAY}├──''${C_RESET} ''${C_BLUE}hyprland.nix''${C_RESET}        : Hyprland 視窗規則、3遍毛玻璃、無暗淡、快捷鍵 (MYHYprLUa)"
      echo -e "      ''${C_GRAY}├──''${C_RESET} ''${C_BLUE}waybar.nix''${C_RESET}          : 3D 水晶底板、遙測膠囊、七曜+時鐘一體化發光膠囊"
      echo -e "      ''${C_GRAY}├──''${C_RESET} ''${C_BLUE}fcitx.nix''${C_RESET}           : Fcitx5 + Rime 四葉草詞庫 + 小鶴雙拼 + 八股文語意模型"
      echo -e "      ''${C_GRAY}├──''${C_RESET} ''${C_BLUE}yazi.nix''${C_RESET}            : Yazi 檔案管理器 (Enter直連Helix, gD跳~/DOwn, Shift+Y複製)"
      echo -e "      ''${C_GRAY}├──''${C_RESET} ''${C_BLUE}helix.nix''${C_RESET}           : Helix 編輯器 (Space+w存檔, Space+Space搜檔, Rust/Nix LSP)"
      echo -e "      ''${C_GRAY}├──''${C_RESET} ''${C_BLUE}kitty.nix''${C_RESET}           : Kitty 終端機 (JetBrainsMono 24pt, 穿透Ctrl+Shift+C給Helix)"
      echo -e "      ''${C_GRAY}├──''${C_RESET} ''${C_BLUE}awww.nix''${C_RESET}            : 桌布引擎 (awww 轉場 + wall-random 抽盲盒 + wall-video 4K影片)"
      echo -e "      ''${C_GRAY}├──''${C_RESET} ''${C_BLUE}alarm.nix''${C_RESET}           : 鬧鐘與紀念日 (remind 指令 + 內建 17KB 6kg.xm 晶片音樂)"
      echo -e "      ''${C_GRAY}├──''${C_RESET} ''${C_BLUE}scripts.nix''${C_RESET}         : 截圖/錄影/翻譯 (shot 瞬時凍結截圖, record-screen, trans-gui)"
      echo -e "      ''${C_GRAY}├──''${C_RESET} ''${C_BLUE}copyfile.nix''${C_RESET}        : CLI 複製檔案實體進 Wayland 剪貼簿 (支援改名, 適配 Dolphin)"
      echo -e "      ''${C_GRAY}├──''${C_RESET} ''${C_BLUE}defaults.nix''${C_RESET}        : 全域預設值 (Chrome瀏覽器, Nemo檔案管理, VLC播放器, Helix編輯)"
      echo -e "      ''${C_GRAY}├──''${C_RESET} ''${C_BLUE}dev.nix''${C_RESET}             : Rust (rustc/cargo/analyzer) + JS/TS (node22/pnpm/bun/biome)"
      echo -e "      ''${C_GRAY}└──''${C_RESET} ''${C_WHITE}apps/''${C_RESET}                : 軟體安裝分流包 (apps-gui, apps-heavy, apps-sec)"

      echo -e "\n''${C_PURPLE}🏠 【用戶家目錄重要資料夾分布 (~/)】''${C_RESET}"
      echo -e "  ''${C_GRAY}•''${C_RESET} ''${C_YELLOW}~/Pictures/Screenshots/''${C_RESET} : shot 截圖自動存檔目錄"
      echo -e "  ''${C_GRAY}•''${C_RESET} ''${C_YELLOW}~/Pictures/Wallhaven/''${C_RESET}   : wall-random 抽取的 2K 壁紙與 4K 影片目錄"
      echo -e "  ''${C_GRAY}•''${C_RESET} ''${C_YELLOW}~/Videos/Recordings/''${C_RESET}    : record-screen 錄影存檔目錄"
      echo -e "  ''${C_GRAY}•''${C_RESET} ''${C_YELLOW}~/DOwn/''${C_RESET}                 : 常用下載目錄 (Yazi 中按 g D 一秒直達)"
      echo -e "  ''${C_GRAY}•''${C_RESET} ''${C_YELLOW}~/.local/share/fcitx5/rime/''${C_RESET} : Rime 詞庫與八股文模型目錄 (來源: e3e0261f/NIxos-RIme-GRam)"
      echo -e "  ''${C_GRAY}•''${C_RESET} ''${C_YELLOW}~/.local/share/easyeffects/irs/''${C_RESET} : EasyEffects 卷積混響 (Convolver) 脈衝響應目錄"
      echo -e "''${C_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━''${C_RESET}"
    }

    # 2. 緊急搶救與回滾手冊 (rhys recover / rhys -r)
    show_recover() {
      show_header
      echo -e "\n''${C_RED}🚨 【緊急搶救與系統回滾操作手冊】''${C_RESET}"
      echo -e "  ''${C_YELLOW}1. 測試失敗或卡死時（1秒熱回滾）:''${C_RESET}"
      echo -e "     ''${C_GREEN}nix-test -r''${C_RESET}                  撤銷當前臨時測試，瞬間退回健康系統"
      echo -e "\n  ''${C_YELLOW}2. 斷網急救（代理崩潰或 DNS 混亂）:''${C_RESET}"
      echo -e "     ''${C_GREEN}sudo systemctl stop dae; echo 'nameserver 223.5.5.5' | sudo tee /etc/resolv.conf''${C_RESET}"
      echo -e "     (掐死代理並注入阿里 DNS，網路立馬復活，即可執行修復或上網查資料)"
      echo -e "\n  ''${C_YELLOW}3. 歷史版本精準跳轉（指定代數）:''${C_RESET}"
      echo -e "     ''${C_GREEN}nix-save -l''${C_RESET}                  查看歷史清單"
      echo -e "     ''${C_GREEN}nix-save -r 158''${C_RESET}              精確跳回第 158 號黃金世代！"
      echo -e "\n  ''${C_YELLOW}4. 開機崩潰救磚（終極底牌）:''${C_RESET}"
      echo -e "     重開機，在引導選單（systemd-boot）中直接上下鍵選擇帶有 ''${C_CYAN}DAE-H3''${C_RESET} 或 ''${C_CYAN}158''${C_RESET} 的世代啟動！"
      echo -e "\n  ''${C_YELLOW}5. Rime 詞庫手動重新編譯:''${C_RESET}"
      echo -e "     ''${C_GREEN}rm -rf ~/.local/share/fcitx5/rime/build && systemctl --user restart fcitx5-daemon''${C_RESET}"
      echo -e "''${C_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━''${C_RESET}"
    }

    # 3. 預設總覽手冊 (rhys / rhys -h)
    show_summary() {
      show_header
      echo -e "\n''${C_PURPLE}❄️  【NixOS 核心指令】''${C_RESET}"
      echo -e "  ''${C_GREEN}nix-test''${C_RESET}                 : 測試編譯當前配置 (不產生世代垃圾)"
      echo -e "  ''${C_GREEN}nix-test -r''${C_RESET}              : ⭐️ 測試失敗時 1 秒熱回滾！"
      echo -e "  ''${C_GREEN}nix-save''${C_RESET}                 : 正式構建世代、重載 Waybar 並 GPG 同步 GitHub"
      echo -e "  ''${C_GREEN}nix-save -l / -r [N]''${C_RESET}     : 查詢世代清單 / 回滾到指定代數 (如: nix-save -r 158)"
      echo -e "  ''${C_GREEN}nix-load''${C_RESET}                 : 從遠端 GitHub 強制拉取最新配置並重構"

      echo -e "\n''${C_BLUE}📁 【檔案、編輯器與剪貼簿 (Yazi / Helix)】''${C_RESET}"
      echo -e "  ''${C_GREEN}y''${C_RESET} 或 ''${C_GREEN}yy''${C_RESET}                   : 啟動 Yazi (退出時終端自動跳轉到所在目錄)"
      echo -e "  ''${C_YELLOW}Super + E''${C_RESET}               : 螢幕正中央彈出 75% 置中懸浮 Yazi"
      echo -e "  ''${C_GRAY}├─ Yazi 內快捷鍵:''${C_RESET}       ''${C_YELLOW}g D''${C_RESET} 跳 ~/DOwn | ''${C_YELLOW}g n''${C_RESET} 跳 /etc/nixos | ''${C_YELLOW}g m''${C_RESET} 跳 modules"
      echo -e "  ''${C_GRAY}└─ Yazi 內複製:''${C_RESET}         選中檔案按 ''${C_YELLOW}Shift + Y''${C_RESET} 複製檔案實體 (可在 Dolphin/網頁 Ctrl+V 貼上)"
      echo -e "  ''${C_GREEN}copyfile <檔1> [新檔名]''${C_RESET}   : 命令行複製檔案實體進剪貼簿 (支援重新命名複製)"
      echo -e "  ''${C_GREEN}hx <檔案>''${C_RESET}                : Helix 編輯器 (Space+Space 搜檔 | Space+w 存檔 | Space+s 查大綱)"

      echo -e "\n''${C_YELLOW}⏰ 【智慧鬧鐘與紀念日 (6kg.xm 晶片音樂)】''${C_RESET}"
      echo -e "  ''${C_GREEN}smart-alarm [標題]''${C_RESET}       : 立即試聽/觸發鬧鐘 (點擊 Mako 通知任意處立刻停播)"
      echo -e "  ''${C_GREEN}remind -d \"07:00\" \"早安\"''${C_RESET}   : 每天早上 07:00 定時鬧鐘"
      echo -e "  ''${C_GREEN}remind -y \"09-10 02:34\" \"名\"''${C_RESET}: 每年該日期定時觸發專屬紀念日"
      echo -e "  ''${C_GREEN}remind ... -f \"/路徑/歌\"''${C_RESET}   : 指定播放外部音樂 (預設為內建 6kg.xm 模組)"
      echo -e "  ''${C_GREEN}remind -l / -c <定時器>''${C_RESET}  : 查詢所有預約清單 / 取消指定定時器"

      echo -e "\n''${C_CYAN}🪟 【桌面、壁紙與音訊操作 (Hyprland / Waybar / PipeWire)】''${C_RESET}"
      echo -e "  ''${C_YELLOW}Super + Ctrl + S''${C_RESET}        : ⭐️ 瞬時定格拉框截圖 (hyprshot --freeze，截選單必備)"
      echo -e "  ''${C_YELLOW}Super + Print''${C_RESET}           : 全螢幕定格秒截 (自動存檔 ~/Pictures/Screenshots)"
      echo -e "  ''${C_YELLOW}Super + S''${C_RESET}               : 呼叫 / 收回 Magic 暫存終端機空間"
      echo -e "  ''${C_YELLOW}Super + Escape''${C_RESET}          : 單向收起 Magic 空間 (按一萬次也絕不誤彈出)"
      echo -e "  ''${C_YELLOW}Super + W''${C_RESET}               : 顯示 / 隱藏 Waybar 狀態列"
      echo -e "  ''${C_YELLOW}Super + Ctrl + W''${C_RESET}        : ⭐️ Wallhaven 隨機抽 2K 桌布 (60FPS 隨機轉場特效)"
      echo -e "  ''${C_GREEN}wall-video [影片路徑]''${C_RESET}     : 隨機播放 ~/Pictures/Wallhaven 的 4K 影片桌布 (MPV IPC 熱加載)"
      echo -e "  ''${C_GREEN}wall-video --stop''${C_RESET}       : 停止動態影片，切回靜態桌布"
      echo -e "  ''${C_GREEN}hyprctl reload''${C_RESET}          : 0.01 秒熱重載 Hyprland 配置 (開著的視窗不關閉)"
      echo -e "  ''${C_GREEN}pw-top''${C_RESET}                  : 即時查看 192kHz 母帶級音訊時鐘與 PipeWire 延遲"

      echo -e "\n''${C_GREEN}🌐 【網路、代理與輸入法】''${C_RESET}"
      echo -e "  ''${C_GREEN}sudo systemctl restart dae''${C_RESET}: 重啟 dae 代理，強制重新測速並清空 DNS 快取"
      echo -e "  ''${C_GREEN}journalctl -u dae -f''${C_RESET}      : 即時查看 dae eBPF 核心分流日誌"
      echo -e "  ''${C_GREEN}appimage-run <.AppImage>''${C_RESET} : 在專屬 FHS 沙盒中一鍵運行任何 AppImage 軟體"
      echo -e "  ''${C_YELLOW}Win + Space''${C_RESET}             : 切換 英文 / 中州韻 (Rime)"
      echo -e "  ''${C_YELLOW}F4 / Ctrl + ~''${C_RESET}                          : 叫出 Rime 方案選單 (小鶴雙拼/自然碼/全拼)"
      echo -e "\n''${C_GRAY}💡 進階指令: 輸入 'rhys files' 查看檔案架構地圖 | 輸入 'rhys recover' 查看緊急搶救指南''${C_RESET}"
      echo -e "''${C_CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━''${C_RESET}"
    }

    # 參數分流
    case "$1" in
      files|-f|--files)
        show_files
        ;;
      recover|-r|--recover|rescue)
        show_recover
        ;;
      help|-h|--help|*)
        show_summary
        ;;
    esac
  '';
in
{
  home.packages = [
    rhysCommand
  ];

  # ⭐️ 給 Fish 加上 rhys 的子命令 Tab 自動補全
  xdg.configFile."fish/completions/rhys.fish".text = ''
    complete -c rhys -s f -l files -d "查看全系統核心與模組檔案架構分布地圖"
    complete -c rhys -s r -l recover -d "查看緊急搶救與斷網/世代回滾手冊"
    complete -c rhys -s h -l help -d "顯示常用指令與快捷鍵總覽手冊"
  '';
}
