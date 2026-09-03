{ pkgs, ... }:

{
  environment.systemPackages = [
    # --- 1. nix-test 腳本：安全測試模式 ---
    (pkgs.writeShellScriptBin "nix-test" ''
      #!/bin/bash
      [ -n "$http_proxy" ] && echo "🌐 代理開啟: $http_proxy" || echo "🌿 直連模式"
      echo "----------------------------------------"
      
      # Lua 語法預檢
      if [ -f ~/.config/hypr/hyprland.lua ]; then
          luajit -bl ~/.config/hypr/hyprland.lua > /dev/null
          if [ $? -ne 0 ]; then
              echo "❌ 警告：~/.config/hypr/hyprland.lua 存在語法錯誤！"
              exit 1
          fi
      fi

      echo "🧪 正在執行安全測試 (nixos-rebuild test)..."
      cd /etc/nixos
      git add .
      sudo nixos-rebuild test --flake .#nixos

      if [ $? -eq 0 ]; then
        echo "✅ 測試成功！目前效果已臨時生效（不佔用開機選單）。"
      else
        echo "❌ 測試失敗，請檢查報錯。"
        exit 1
      fi
    '')

    # --- 2. nix-save 腳本：正式構建並同步 GitHub ---
    (pkgs.writeShellScriptBin "nix-save" ''
      #!/bin/bash
      [ -n "$http_proxy" ] && echo "🌐 代理開啟: $http_proxy" || echo "🌿 直連模式"
      echo "----------------------------------------"

      if [ -f ~/.config/hypr/hyprland.lua ]; then
          luajit -bl ~/.config/hypr/hyprland.lua > /dev/null
          if [ $? -ne 0 ]; then
              echo "❌ 警告：~/.config/hypr/hyprland.lua 存在語法錯誤！"
              read -p "⚠️ 是否強行繼續？ [y/N] " emergency
              [[ ! "$emergency" =~ ^[Yy]$ ]] && exit 1
          fi
      fi

      cd /etc/nixos
      git add .
      echo "正在執行正式構建 (nixos-rebuild switch)..."
      sudo nixos-rebuild switch --flake .#nixos

      if [ $? -eq 0 ]; then
        echo "✅ 構建並生成新世代成功！"
        read -p "🚀 是否同步至 GitHub? [Y/n] " confirm
        confirm=''${confirm:-Y}
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            current_date=$(date "+%Y-%m-%d %H:%M:%S")
            git commit -m "Save config: $current_date"
            git push origin main
            echo "🎉 全部完成！已同步至 GitHub。"
        else
            echo "📦 已取消同步。僅在本地生成世代。"
        fi
      else
        echo "❌ 構建失敗，取消後續動作。"
        exit 1
      fi
    '')

    # --- 3. nix-load 腳本：雲端同步重置 ---
    (pkgs.writeShellScriptBin "nix-load" ''
      set -e
      echo "📥 開始從 GitHub 拉取遠端配置..."
      cd /etc/nixos

      TIMESTAMP=$(date "+%Y%m%d_%H%M%S")
      BACKUP_DIR="/etc/nixos/old/backup_$TIMESTAMP"
      mkdir -p "$BACKUP_DIR"

      echo "📦 正在備份目前配置至 $BACKUP_DIR ..."
      find . -maxdepth 1 ! -name "." ! -name ".git" ! -name "old" ! -name "README.md" -exec mv {} "$BACKUP_DIR/" \;

      echo "🔄 正在與遠端倉庫同步 (git reset --hard)..."
      git fetch origin main
      git reset --hard origin/main

      echo "🚀 同步完成！準備執行系統構建..."
      sudo nixos-rebuild switch --flake .#nixos

      if [ $? -eq 0 ]; then
        echo "✨ 系統已成功恢復為遠端最新版本。"
      else
        echo "❌ 構建失敗，備份保存在 $BACKUP_DIR。"
        exit 1
      fi
    '')
  ];
}
