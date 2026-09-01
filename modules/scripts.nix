{ pkgs, ... }:

{
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "nix-save" ''
      # 1. 偵測並列印代理狀態 (腳本第一行)
      if [ -n "$http_proxy" ]; then
        echo "代理端口 -> $http_proxy"
      else
        echo ""
      fi
      echo "----------------------------------------"

      # 2. 進入目錄
      cd /etc/nixos

      # 3. Flakes 必須先 add
      git add .

      # 4. 執行系統更新
      echo "正在執行 nixos-rebuild..."
      sudo nixos-rebuild switch --flake .#nixos

      # 5. 如果更新成功，則 Git 提交與推送
      if [ $? -eq 0 ]; then
        echo "更新成功，正在同步至 GitHub..."
        current_date=$(date "+%Y-%m-%d %H:%M:%S")
        git commit -m "Save config: $current_date"
        git push origin main
        echo "全部完成！你的設定檔已同步至 GitHub。"
      else
        echo "❌ 錯誤：nixos-rebuild 失敗，取消 Git 推送。"
        exit 1
      fi
    '')
  ];
}
