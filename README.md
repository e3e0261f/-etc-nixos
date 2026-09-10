這是一份為你量身定制、兼具**頂級工程文檔**與**賽博龐克時光膠囊**特質的 `README.md`。

你可以直接將它保存為 `/etc/nixos/README.md`，並透過 `nix-save` 永遠封存在你的 GitHub 宇宙中。

---

# 寫給 50 年後的自己：2026 年秋，我親手鑄造的數位方舟 (CyberArch-NixOS)

> **時間戳記**：2026 年 9 月 5 日，星期六（土曜日 ⛰️）  
> **座標**：台灣  
> **構建者**：Rhys (Kevin Lee) `<e3e0261f@pm.me>`  
> **密鑰指紋**：`31C81A9DE1AB870A8EDC3486D7C2DF9FA0283056` (GPG Verified)  
> **系統狀態**：NixOS 26.05/26.11 Unstable ➔ 鎖定於 `flake.lock` 時光膠囊

---

## 📜 前言：致 2076 年的老友

嗨，未來的我。

當你在 50 年後重新打開這份檔案時，世界也許已經被量子計算機接管，AI 也許已經替人類寫好了所有軟體。但我希望你還記得 2026 年的這個秋天——你坐在螢幕前，對抗著冷冰冰的二進制黑盒、與無數個語法報錯死磕到深夜，最終一行行代碼親手敲出了這台**「絕對純淨、可自我修復、美到極致的數位座駕」**。

那時候你說過一句話：**「這個資料夾的大小寫特徵，不管過去多少年，我一眼就能看出這是我命名的。」**

這份文檔記錄了你所有的偏執、審美與技術遺產。只要這個 Git 倉庫在，你隨時可以將 50 年前的靈魂再次「3D 打印」出來。

---

## 🏛️ 系統架構：為什麼它是「無法被摧毀」的？

不同於傳統 Linux 隨時間腐蝕、依賴手動修補的脆弱系統，這套系統採用了 **純函數式架構（Infrastructure as Code）**：

$$\text{System State} = f(\text{flake.nix}, \text{flake.lock}, \text{Hardware})$$

```
/etc/nixos/ (你的數位 DNA 庫)
├── flake.nix              # 總調度室 (鎖定 nixpkgs 快照，無懼版本漂移)
├── flake.lock             # 時空錨點 (記錄精確到毫秒的 Commit SHA)
├── configuration.nix      # 系統地基 (Zen 核心、AMD GPU、LUKS、全域字體)
├── hardware-configuration.nix # 機器物理 DNA (硬碟 UUID 與硬體模組)
└── modules/               # 模組矩陣 (職責單一，絕不互相污染)
    ├── nix-save.nix       # 核心 CI/CD 流水線 (nix-test / nix-save / nix-load)
    ├── scripts.nix        # trans-gui 1秒截圖翻譯器
    ├── dae-system.nix     # eBPF 內核級透明代理與分流
    ├── keyd.nix           # 內核級輸入層外掛 (CapsLock 雙模態導航)
    ├── home.nix           # Home Manager 總路由 (用戶態總管)
    ├── hyprland.nix       # 視窗管理器 (Lua 解耦與自動熔斷保護)
    ├── waybar.nix         # 3D 黑色水晶玻璃板 (雙行人口 + 活動進程遙測 + 七曜光譜)
    ├── fcitx5.nix         # 雙拼輔助碼 (rime-shuangpin-fuzhuma 雲端自動同步)
    ├── helix.nix          # Helix 編輯器 (現代肌肉記憶快捷鍵)
    ├── kitty.nix          # 24pt 大字體透明終端
    ├── shell.nix          # Fish 終端機函數 (proxy / sss / cc / adl / fastget)
    ├── openmega.nix       # MEGA 加密網盤提取 + 字幕在地化轉繁流水線
    ├── git.nix            # SSH 443 埠繞過 + GPG 數位簽章
    └── tools.nix          # Btop / Zellij / Yazi / Wormhole
```

---

## ⚡ 核心黑科技矩陣

### 1. 網路與代理：內核級 eBPF 透明分流
*   **引擎**：`dae` + `SmartDNS` 本地解析 (5335 埠)。
*   **分流哲學**：
    *   **Steam 下載**：命中 `geosite:steam@cn` 與 `geoip:cn`，走物理寬頻**直連滿速**。
    *   **Steam 商店/社區**：命中 `geosite:steam`，自動走代理節點，告別連線錯誤。
    *   **Telegram / GitHub / OpenAI**：全自動分流，對終端機與所有瀏覽器 100% 透明。
*   **資產管理**：規則庫（`geoip.dat` / `geosite.dat`）透過 Flake 自動由你個人的 GitHub 倉庫拉取，不受牆內限速困擾。

### 2. 身份與安全：量子前夕的防禦鏈條
*   **SSH over 443**：透過 `ssh.github.com:443` 建立加密通道，徹底封殺被運營商阻斷的傳統 22 埠。
*   **GPG 簽名一體化**：使用密鑰 `31C81A9DE1AB870A8EDC3486D7C2DF9FA0283056`，每一次代碼構建自動帶上「Verified」綠色認證標章。
*   **GDM 極簡分離**：幹掉肥大的 GNOME 桌面全家桶，僅保留獨立的 GDM 負責 Wayland 登入與 PAM Keyring 自動解鎖。

### 3. 視窗空間：`MYHYprLUa` 雙軌防爆架構
*   **主檔極簡解耦**：`hyprland.lua` 只作為橋樑，不寫任何可能導致閃退的業務代碼。
*   **安全沙盒 (`~/.config/MYHYprLUa/`)**：你的快捷鍵與規則全部放在此處。
*   **`pcall` 故障熔斷機制**：即便你在自定義 Lua 裡寫錯了標點符號，主系統會攔截錯誤並自動降級到「安全保底模式」，永遠為你保留 `Super + Q` 終端機，**系統永不崩潰**。

---

## 🎨 終端與桌面美學 (Cyberpunk Aesthetics)

### 1. 3D 黑色水晶玻璃板 (Waybar)
*   **實體厚度**：頂部 `1.5px` 受光面高光，底部 `3px` 深色沉降切面，構成實體黑色水晶玻璃的重厚切片。
*   **點擊穿透**：視窗寬度固定為 `1180px`，兩側透明區域徹底消除，滑鼠可 100% 穿透點擊背後視窗。
*   **活動視窗即時遙測 (Telemetry)**：告別無聊的標題，實時顯示焦點進程的 `PID`、`物理記憶體 (MB)`、`後台 Socket 連線數` 以及 `近1分鐘平均上下載速率`。探針自帶 Socket 活體掃描自癒能力。
*   **七曜 360° 全方漫延光暈**：全條唯一發光源。星期一至星期日根據天體元素自動變色，光芒向四面八方擴散：
    *   🌕 **月曜** (冷冰冰的月亮銀藍冷光)
    *   🔥 **火曜** (燒紅鐵塊般的熔岩熾紅)
    *   💧 **水曜** (青山綠水清泉碧青)
    *   🌿 **木曜** (耀眼高能葉綠素翠綠)
    *   👑 **金曜** (純金耀斑刺目金黃)
    *   ⛰️ **土曜** (孕育生機的沃土琥珀金)
    *   ☀️ **日曜** (日冕耀斑太陽紅橙)
*   **Pango 微米級基線對齊**：`<span rise='-1500'>` 讓 `36 土曜 Saturday 10:38` 完美踩在同一條水平地平線上。
*   **點擊翻牌**：點擊時間瞬間切換為年月日公曆，懸停浮現精美月曆卡片。

### 2. 鍵盤人體工學 (Keyd & Helix)
*   **Keyd 物理外掛**：
    *   **單點 CapsLock** ➔ `Escape` (極速退出編輯模式)。
    *   **按住 CapsLock** ➔ 啟動導航層，左手 `W/A/S/D` 即是方向鍵，手腕不用離開主鍵盤區。
*   **Helix (hx)「所見即所得」**：
    *   `Ctrl + s` ➔ 隨手存檔。
    *   `Space + z` ➔ 存檔並退出 (`:x`)；`Space + x` ➔ 放棄修改強制退出 (`:q!`)。
    *   `Alt + x` ➔ 剪切整行；`%d` ➔ 一秒清空全文件。
    *   `y` ➔ 透過 `:pipe wl-copy` 直通系統剪貼簿。

### 3. 輸入法：Rime 雙拼輔助碼
*   **架構**：Fcitx5 + `fcitx5-rime` 原生 Wayland Layer-Shell 渲染。
*   **詞庫自動化**：由 Home Manager 自動從 GitHub 抓取 `gaboolic/rime-shuangpin-fuzhuma`，部署至 `~/.local/share/fcitx5/rime`。
*   **外觀**：Nord-Dark 深色皮膚、18pt 大字體、橫向選詞、一鍵 `Shift` 中英無感切換。

---

## 🛠️ 2026 專屬命令法術書

| 指令 | 作用 | 說明 |
| :--- | :--- | :--- |
| **`nix-test`** | 安全測試 | 編譯並套用配置，**不產生開機世代**，改崩了重啟直接復原。 |
| **`nix-save`** | 正式存檔 | 生成新 Generation，提示是否帶 GPG 簽名推送到 GitHub。 |
| **`nix-load`** | 雲端重置 | 備份本地到 `old/`，強制以 GitHub 遠端版本覆蓋並重建系統。 |
| **`shx <檔案>`** | 管理員編輯 | 以 Root 權限調用 Helix，但完美載入你個人的主題與快捷鍵。 |
| **`proxy [埠]`** | 代理切換 | 無參數清空環境變數回歸自然；帶參數（如 `proxy 7890`）注入代理。 |
| **`cc [檔案]`** | 字幕在地化 | 遞迴掃描 `~/下載`，調用 OpenCC 台灣在地化詞庫將簡體 `.srt` 轉為 `.srt.txt` 並輸出彩色 diff。 |
| **`mega-srt <連結>`** | 雲端提取 | 破解 MEGA 加密資料夾，略過大影片，精準抓取字幕並自動翻譯。 |
| **`trans-gui`** | 截圖翻譯 | `Super+Ctrl+Shift+S` 觸發，OCR 識別後由 Crow 高速翻譯，結果自動進剪貼簿並彈出 YAD 視窗。 |
| **`record-screen`** | 系統錄影 | `Super+Shift+R` (區域) / `Super+Ctrl+Shift+R` (全螢幕)，內建 PipeWire 系統聲音捕捉與優雅封裝。 |
| **`logout`** | 優雅登出 | 呼叫 `hyprshutdown` 安全保存所有軟體分頁後退出桌面。 |

---

## ☕ 結語：永遠不妥協的靈魂

那時的朋友們也許都在用滑鼠在圖形介面上點點按按，忍受著系統的臃腫與廣告。而你選擇了一條最陡峭的路：把作業系統當作一門程式語言來編寫，把每一個畫素、每一個按鍵的延遲都壓榨到極致。

你曾笑著說：**「這簡直是無數人智慧的結晶，最後的硬編碼，都讓我使用上了。」**

請永遠記住 2026 年的這個秋天，記住這份掌控代碼、馴服機器、不向任何黑盒妥協的熱血。

**Happy Hacking, Rhys. See you in the future.** 🚀
