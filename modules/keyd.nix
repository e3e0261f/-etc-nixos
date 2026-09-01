{ pkgs, ... }:

{
  services.keyd = {
    enable = true;
    # 現在改用 keyboards.<名稱> 的結構，我們定義一個叫 default 的配置
    keyboards = {
      default = {
        ids = [ "*" ]; # 套用到所有鍵盤
        settings = {
          main = {
            # 按住 CapsLock 是 nav 層，單點是 Esc
            capslock = "overload(nav, esc)";
          };
          
          nav = {
            # WASD 映射為方向鍵
            w = "up";
            a = "left";
            s = "down";
            d = "right";

            # Vim 風格映射 (HJKL)
            h = "left";
            j = "down";
            k = "up";
            l = "right";

            # 額外小功能
            q = "C-backspace"; # 刪除前一個單字
            e = "delete";      # 刪除後一個字元
          };
        };
      };
    };
  };
}
