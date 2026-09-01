{ pkgs, ... }:

{
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "nix-save" ''
      # 1. 偵測代理狀態
      if [ -n "$http_proxy" ]; then
        echo "🌐 目前環境：【代理開啟】 -> $http_proxy"
      else
        echo "🌿 目前環境：【直連模式】"
      fi
      echo "----------------------------------------"

      # 2. 準備構建
      cd /etc/nixos
      git add .

      echo "正在執行 nixos-rebuild..."
      sudo nixos-rebuild switch --flake .#nixos

      # 3. 判斷構建結果
      if [ $? -eq 0 ]; then
        echo "----------------------------------------"
        echo "✅ 更新成功！"
        
        # 4. Y/N 互動選項 (預設為 Y)
        # -n 1: 只要輸入一個字元就繼續; -p: 提示文字
        read -p "🚀 是否同步至 GitHub? [Y/n] " confirm
        confirm=''${confirm:-Y} # 如果直接按回車，預設值為 Y

        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            current_date=$(date "+%Y-%m-%d %H:%M:%S")
            git commit -m "Save config: $current_date"
            
            echo "正在上傳..."
            git push origin main
            echo "🎉 全部完成！設定檔已同步至 GitHub。"
        else
            echo "📦 已取消同步。設定檔僅保存在本地 /etc/nixos。"
        fi
      else
        echo "❌ 錯誤：nixos-rebuild 失敗，取消後續動作。"
        exit 1
      fi
    '')
  ];
}
