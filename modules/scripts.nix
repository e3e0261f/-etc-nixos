{ pkgs, ... }:

{
  environment.systemPackages = [
    # --- 原有的 nix-save 腳本 ---
     (pkgs.writeShellScriptBin "nix-save" ''
      #!/bin/bash
      if [ -n "$http_proxy" ]; then
        echo "🌐 目前環境：【代理開啟】 -> $http_proxy"
      else
        echo "🌿 目前環境：【直連模式】"
      fi
      echo "----------------------------------------"
      # --- 1. Lua 語法預檢 (質檢掃描儀) ---
      echo "🔍 正在進行 Lua 語法安全檢查..."
      
      # 我們建立一個臨時文件來模擬最終生成的 Lua 代碼
      # 這裡主要檢查 modules/hyprland.nix 裡注入的內容
      # 2026 程序員技巧：直接用 luajit -bl 檢查語法而不執行
      
      # 雖然在 Nix 環境下檢查內部字串較難，但我們可以先檢查本地緩存
      if [ -f ~/.config/hypr/hyprland.lua ]; then
          luajit -bl ~/.config/hypr/hyprland.lua > /dev/null
          if [ $? -ne 0 ]; then
              echo "❌ 警告：目前的 ~/.config/hypr/hyprland.lua 存在語法錯誤！"
              echo "請修正代碼後再執行同步，以免無法登入。"
              read -p "⚠️ 是否強行繼續？ [y/N] " emergency
              [[ ! "$emergency" =~ ^[Yy]$ ]] && exit 1
          fi
      fi
      echo "----------------------------------------"
      cd /etc/nixos
      git add .
      echo "正在執行 nixos-rebuild..."
      sudo nixos-rebuild test --flake .#nixos
      if [ $? -eq 0 ]; then
        echo "✅ 更新成功！"
        read -p "🚀 是否同步至 GitHub? [Y/n] " confirm
        confirm=''${confirm:-Y}
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            current_date=$(date "+%Y-%m-%d %H:%M:%S")
            git commit -m "Save config: $current_date"
            git push origin main
            echo "🎉 全部完成！"
        else
            echo "📦 已取消同步。"
        fi
      else
        echo "❌ 失敗。"
        exit 1
      fi
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
