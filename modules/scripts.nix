{ pkgs, ... }:

{
  environment.systemPackages = [
    # --- 原有的 nix-save 腳本 ---
    (pkgs.writeShellScriptBin "nix-save" ''
       # ... (保持你之前的代碼，含 Y/N 選項) ...
    '')

    # --- 新增的 nix-load 腳本 (雲端同步重置) ---
    (pkgs.writeShellScriptBin "nix-load" ''
      set -e # 遇到錯誤立刻停止
      
      echo "📥 開始從 GitHub 拉取遠端配置..."
      cd /etc/nixos

      # 1. 準備備份目錄
      TIMESTAMP=$(date "+%Y%m%d_%H%M%S")
      BACKUP_DIR="/etc/nixos/old/backup_$TIMESTAMP"
      mkdir -p "$BACKUP_DIR"

      echo "📦 正在備份目前配置至 $BACKUP_DIR ..."
      
      # 2. 移動檔案 (排除 .git, old 資料夾和腳本自己)
      # 使用 find 找出當前目錄的所有檔案和資料夾，排除不需要移動的
      find . -maxdepth 1 ! -name "." ! -name ".git" ! -name "old" ! -name "README.md" -exec mv {} "$BACKUP_DIR/" \;

      echo "🔄 正在與遠端倉庫同步 (git reset --hard)..."
      
      # 3. 強制同步遠端
      git fetch origin main
      git reset --hard origin/main

      echo "🚀 同步完成！準備執行系統構建..."
      
      # 4. 執行構建
      sudo nixos-rebuild switch --flake .#nixos

      if [ $? -eq 0 ]; then
        echo "✨ 恭喜！系統已成功恢復為遠端最新版本。"
      else
        echo "❌ 構建失敗，請檢查遠端代碼是否有誤。"
        echo "💡 你可以在 $BACKUP_DIR 找回剛才的備份。"
        exit 1
      fi
    '')
  ];
}
