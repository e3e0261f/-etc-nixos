sudo nixos-rebuild switch --option substituters "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store https://cache.nixos.org"

nix.settings.substituters = [
  "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
  "https://cache.nixos.org"
];

wget https://mirrors.ustc.edu.cn/nixos-images/nixos-24.11/nixos-graphical-24.11-x86_64-linux.iso

wget https://mirrors.tuna.tsinghua.edu.cn/nixos-images/nixos-24.11/nixos-graphical-24.11-x86_64-linux.iso

在国内重装 NixOS，最核心的避坑逻辑是：“镜像源先换好、网络通道准备好、离线配置留备份”。因为 NixOS 极度依赖在线拉取软件包和 Git 仓库，一旦在安装环境（Installer Live Environment）里没网或没设镜像源，重装过程会非常痛苦。以下为你整理的“NixOS 国内重装救命清单与关键命令”：1. 准备工作（安装前的救命备份）备份 /etc/nixos 文件夹：确保你最新的 flake.nix、hardware-configuration.nix 和 configuration.nix 已经成功 git push 到 GitHub，或者手动打包拷贝到 U 盘里。记录磁盘分区信息：在旧系统里最后运行一次 lsblk -f 并截图/保存，明确你的系统盘（如 /dev/nvme0n1）以及 EFI 分区位置。2. 引导进 Live 系统后的“救命第一步”（网络与镜像源）启动进 NixOS ISO 安装环境后，千万不要直接运行 nixos-install，先配置国内源！① 确认网络连接Bashping -c 3 baidu.com
如果是 Wi-Fi，运行 nmtui 图形化连接无线网络。② 临时启用清华/中科大二进制缓存源（救命关键）在 Live 系统中，编辑 /etc/nix/nix.conf（如果不存在则新建）：Bashsudo mkdir -p /etc/nix
sudo nano /etc/nix/nix.conf
贴入以下内容，强制让 Nix 走国内镜像站下载所有依赖：Plaintextsubstituters = https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store https://cache.nixos.org
experimental-features = nix-command flakes
3. 磁盘挂载与配置准备假设你已经分好了区（例如 /dev/nvme0n1p2 是根分区，/dev/nvme0n1p1 是 EFI 分区）：Bash# 1. 挂载根分区
sudo mount /dev/nvme0n1p2 /mnt

# 2. 挂载 Boot/EFI 分区
sudo mkdir -p /mnt/boot
sudo mount /dev/nvme0n1p1 /mnt/boot

# 3. 将你的配置拷贝回 /mnt/etc/nixos
sudo mkdir -p /mnt/etc/nixos
# 如果有 Git 备份，直接 clone（或者从 U 盘复制）
sudo git clone https://github.com/你的用户名/你的配置仓库.git /mnt/etc/nixos
4. 安装阶段的救命命令在执行安装时，一定要在命令中显式带上国内镜像源参数，防止它跳回官方源卡死：如果你使用的是传统的 configuration.nix：Bashsudo nixos-install --option substituters "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store https://cache.nixos.org"
如果你使用的是 Flakes 架构（如 flake.nix）：Bashsudo nixos-install --flake /mnt/etc/nixos#你的主机名 --option substituters "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store https://cache.nixos.org"
5. 新系统首次启动后的配置（写死国内源）重装成功并重启进入新系统后，为了确保以后每次 nix-save 或 nix-test 速度飞快，请确保你的 configuration.nix（或 Flake 引入的模块）中写死了镜像源：Nix# 在 configuration.nix 中添加
nix.settings = {
  substituters = [
    "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
    "https://cache.nixos.org"
  ];
  # 自动清理旧世代，节省空间
  auto-optimise-store = true;
};
6. 一句话救命速查表（急救卡片）GitHub 拉不下来配置？ -> 使用 ghproxy 镜像代理：git clone [https://mirror.ghproxy.com/https://github.com/你的用户名/仓库.git](https://mirror.ghproxy.com/https://github.com/你的用户名/仓库.git)Nix 下载一直卡在 0% 或超时？ -> 检查是否忘记加 --option substituters "[https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store](https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store)"。找不到硬件配置？ -> 在 /mnt 下运行 sudo nixos-generate-config --root /mnt 生成最新的 hardware-configuration.nix。当前功能列表总结nix-test：支持热回滚（-r / --rollback），恢复至健康世代并平滑刷新 Waybar。   自动检测并运行 ~/.config/hypr/hyprland.lua 的 Lua 语法安全检查。   包含 git add -A 并自动提交 git commit -m "TEst"，彻底清空 Git tree is dirty 警告。   临时生效测试配置 (nixos-rebuild test)，测试成功后自动刷新 Waybar。   nix-save：支持查询历史世代清单（-l / --list）。   支持精准世代回滚（-r [世代号]）或回滚至上一代（-r）。   整合 Lua 语法安全检查（含强行继续的交互确认）。   升级为 git add -A 并自动执行正式构建 (nixos-rebuild switch)。   自动提示是否 commit 并同步（git push）至 GitHub 远程仓库。   nix-load：强制从 GitHub 远程 main 分支拉取最新配置。   自动在 /etc/nixos/old/ 下创建带有时间戳的完整备份。   执行 git reset --hard 并重建系统。   trans-gui：划词/区域截图（grim + slurp）并使用 Tesseract OCR 识图。   调用 Crow Translate 翻译为繁体/简体中文，结果自动复制到剪贴板并弹窗显示（YAD GUI）。



######

2026 年程式員的「自救佈局」建議：
######
如果你真的擔心「沒 AI 就廢了」，你應該在你的 /etc/nixos 裡建立一個 CHEATSHEET.md (自救秘笈)，裡面只記幾行命令：
nix-env -qaP 軟體名：在沒有 AI 的情況下，這條命令能告訴你某個軟體在目前的庫裡到底叫什麼。
nixos-rebuild list-generations：看看到底有多少個歷史版本可以回退。
git log：看看你昨天改了什麼導致今天崩潰。



1. 直接在新電腦「復原」目前狀態
######
答案：完全可以直接使用，且 100% 不會失效。
為什麼？ 因為你現在有了 flake.lock。
原理：flake.lock 就像一張精確到秒的「快照」。它記錄了你目前使用的 nixpkgs 在 GitHub 上的精確 Commit ID（例如 34ab990...）。
結果：哪怕是五年後，你在新電腦上執行

nixos-rebuild switch --flake .#nixos

Nix 會根據 Lock 檔案去抓取 2026 年 8 月 31 日 的代碼。在那個時空的代碼庫裡，包名還是舊的，邏輯還是舊的。
結論：只要你不刪除 flake.lock，這份設定檔就是一個**「時光膠囊」**，永遠有效。


2. 情況二：在新系統裡「更新」軟體包
答案：如果不修改代碼，直接更新（Update）可能會報錯。
場景：兩年後，你想用最新版的內核，於是你執行了 nix flake update。
發生了什麼：flake.lock 被更新到了 2028 年的 nixpkgs。此時，2028 年的庫裡可能已經把 fcitx5-chinese-addons 徹底刪除或改名了。
結果：執行 nix-save 時，系統會報錯：error: undefined variable 'fcitx5-chinese-addons'。
這就是你擔心的「失效」。
3. 沒有 AI 幫忙，你該如何「聯動」或「自救」？
這正是 2026 年程式員需要具備的「系統管理能力」。即便沒有 AI，NixOS 也提供了足夠的工具讓你自救：
A. 利用 Nix 內建的搜尋功能（手動找回包名）
如果編譯報錯說找不到某個包，你只需要在終端機輸入：
code
Bash
nix search nixpkgs 關鍵字
例如：nix search nixpkgs fcitx5-chinese。它會列出目前庫裡所有相關的正確名稱。你只需要把設定檔裡的舊名字改掉即可。
B. 閱讀「誠實」的報錯訊息
Nix 的報錯其實比 AI 更有用。你之前看到的：
error: 'fcitx5-chinese-addons' has been renamed to 'qt6Packages.fcitx5-chinese-addons'
這不是報錯，這是**「遷移指南」**。系統直接告訴你答案了，你只需要複製、貼上，連腦袋都不用動。
C. 保持「硬體隔離」
你要記住，唯一不能直接複製到新系統的檔案是 hardware-configuration.nix。
正確的做法：
在新電腦裝好基礎 NixOS。
保留新電腦生成的 hardware-configuration.nix。
把你 GitHub 上的 configuration.nix 和 modules/ 資料夾拷貝過來覆蓋。
跑一下 nix-save。
瞬間完成遷移。


NixOS 還藏了什麼「核武器」級的東西？
這個團隊確實非常強大，他們的思維領先了主流作業系統（Windows/macOS）整整 20 年。除了 Flakes，還有幾個目前處於「實驗性」或「高端玩家專屬」的黑科技：
<!-- A. Content-Addressed Derivations (內容定址派生) —— 終極節能黑科技 -->
目前的痛點：如果你在原始碼裡改了一個註釋（對執行完全沒影響），Nix 依然會因為原始碼 Hash 變了而重新編譯整個軟體及其依賴項。
黑科技內容：這個功能開啟後，Nix 會檢查編譯後的結果。如果編譯出來的二進制檔案沒變，它會自動「跳過」所有下游軟體的重新編譯。
開啟方式：experimental-features = [ "ca-derivations" ]。
<!-- B. NixOS 虛擬機集成測試 (NixOS Tests) —— 系統級的單元測試 -->
黑科技內容：你可以在 configuration.nix 裡寫一段測試腳本（甚至可以包含 Python 代碼）。當你執行 rebuild 時，Nix 會自動啟動一個後台虛擬機，進入你的新系統，自動模擬滑鼠點擊、測試網頁是否能打開、dae 是否通暢。
意義：如果測試沒通過，系統拒絕更新。這保證了你的伺服器或桌面「上線即穩定」。
<!-- C. Remote Deployment (遠端佈署) -->
黑科技內容：你可以在你這台強大的主機上寫好代碼，然後輸入：
nixos-rebuild switch --target-host root@另一台電腦IP
意義：你這台電腦會幫那台弱小的電腦（比如樹莓派或雲端 VPS）編譯好所有軟體包，然後透過網路「推」過去。那台電腦不需要安裝編譯器，瞬間就變成了你設定的樣子。
<!-- D. MicroVM.nix -->
黑科技內容：它能把 NixOS 的服務打包成極小的、毫秒級啟動的微型虛擬機（只有幾 MB）。
意義：你可以讓 smartdns 跑在一個完全隔離的沙盒裡，它的權限被嚴格鎖死，就算被駭客攻破，也碰不到你的主系統。


