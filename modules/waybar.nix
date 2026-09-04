{ pkgs, ... }:

let
  activeAppTelemetry = pkgs.writeScriptBin "active-app-telemetry" ''
    #!${pkgs.python3}/bin/python3
    import json, os, subprocess, time

    STATE_FILE = "/tmp/hypr_active_app_telemetry.json"

    def get_active_window():
        try:
            out = subprocess.check_output(["hyprctl", "activewindow", "-j"], text=True)
            data = json.loads(out)
            return data if data and data.get("pid") else None
        except: return None

    def get_proc_stats(pid):
        rss_mb, sockets, rchar, wchar = 0, 0, 0, 0
        try:
            with open(f"/proc/{pid}/status", "r") as f:
                for line in f:
                    if line.startswith("VmRSS:"):
                        rss_mb = int(line.split()[1]) // 1024
                        break
        except: pass
        try:
            fd_dir = f"/proc/{pid}/fd"
            for entry in os.listdir(fd_dir):
                try:
                    if os.readlink(os.path.join(fd_dir, entry)).startswith("socket:"):
                        sockets += 1
                except: continue
        except: pass
        try:
            with open(f"/proc/{pid}/io", "r") as f:
                for line in f:
                    if line.startswith("rchar:"): rchar = int(line.split()[1])
                    elif line.startswith("wchar:"): wchar = int(line.split()[1])
        except: pass
        return rss_mb, sockets, rchar, wchar

    def format_bytes(b):
        if b < 1024: return f"{int(b):>3}B"
        elif b < 1024 * 1024: return f"{b/1024:>4.1f}K"
        elif b < 1024 * 1024 * 1024: return f"{b/(1024*1024):>4.1f}M"
        else: return f"{b/(1024*1024*1024):>4.1f}G"

    def main():
        win = get_active_window()
        if not win:
            print(json.dumps({"text": "󰌌 桌面", "tooltip": "目前無活動視窗"}))
            return

        pid = win["pid"]
        app_name = win.get("class") or win.get("initialClass") or "App"
        now = time.time()
        rss_mb, sockets, rchar, wchar = get_proc_stats(pid)

        state = {}
        if os.path.exists(STATE_FILE):
            try:
                with open(STATE_FILE, "r") as f: state = json.load(f)
            except: pass

        history = state.get(str(pid), [])
        history.append([now, rchar, wchar])
        history = [h for h in history if now - h[0] <= 65]
        state[str(pid)] = history
        state = {k: v for k, v in state.items() if os.path.exists(f"/proc/{k}")}

        try:
            with open(STATE_FILE, "w") as f: json.dump(state, f)
        except: pass

        down, up = " 0.0B/s", " 0.0B/s"
        if len(history) >= 2:
            td = history[-1][0] - history[0][0]
            if td > 0.8:
                rd = max(0, history[-1][1] - history[0][1])
                wd = max(0, history[-1][2] - history[0][2])
                down = f"{format_bytes(rd / td)}/s"
                up = f"{format_bytes(wd / td)}/s"

        text = f"{app_name}   {rss_mb:>4}M  󰌘 {sockets:>2}  󰇚 {down} 󰕒 {up}"
        tooltip = f"應用: {app_name}\nPID: {pid}\nRSS: {rss_mb} MB\nSockets: {sockets}\nDL: {down} | UL: {up}"
        print(json.dumps({"text": text, "tooltip": tooltip}))

    if __name__ == "__main__": main()
  '';

  # 💡 日文與週數生成腳本 (帶獨立 Pango Rise 控制)
  jpDayScript = pkgs.writeShellScriptBin "jp-day" ''
    #!/bin/bash
    W=$(date +%V)
    D=$(date +%u)
    case $D in
      1) J="月曜"; C="youbi-getsu";;
      2) J="火曜"; C="youbi-ka";;
      3) J="水曜"; C="youbi-sui";;
      4) J="木曜"; C="youbi-moku";;
      5) J="金曜"; C="youbi-kin";;
      6) J="土曜"; C="youbi-do";;
      7) J="日曜"; C="youbi-nichi";;
    esac
    
    # 🎯 高度微調區 (單位：微米 pango units)
    # 若數字偏高，就把 W_RISE 調成負數 (-500)；若漢字偏高，把 J_RISE 調成負數 (-1500)
    W_RISE="0"
    J_RISE="-1500"
    
    TEXT="<span rise='$W_RISE'>$W</span> <span rise='$J_RISE'>$J</span>"
    cat <<EOF
    {"text": "$TEXT", "class": "$C"}
    EOF
  '';
in
{

  xdg.configFile."waybar/config.jsonc".text = ''
    {
      "layer": "top",
      "position": "bottom",
      "height": 38,
      "margin-bottom": 8,
      "exclusive": false,
      "fixed-center": true,
      "ipc": true,
      "modules-center": [
        "hyprland/workspaces",
        "custom/app-telemetry",
        "custom/population",
        "pulseaudio",
        "network",
        "cpu",
        "memory",
        "custom/jp-day",
        "clock",
        "tray"
      ],

      "custom/app-telemetry": {
        "exec": "${activeAppTelemetry}/bin/active-app-telemetry",
        "return-type": "json",
        "interval": 2,
        "format": "{}"
      },

      "custom/population": {
        "exec": "awk 'BEGIN{printf \"%.0f\\nPPL\\n\", 8185000000 + (systime() - 1704067200)*2.4}'",
        "format": "{}",
        "interval": 2,
        "tooltip": false
      },

      "custom/jp-day": {
        "exec": "${jpDayScript}/bin/jp-day",
        "return-type": "json",
        "interval": 60,
        "tooltip": false
      },

      "clock": {
        // 🎯 英文星期與時間的高度微調區
        // 如果 Friday 偏高，可以在這裡調整 rise='-500'
        // 💡 修正：把 %A 和 %H:%M 放在同一個括號裡，解決 C++ 參數缺失報錯！
        "format": "<span rise='0'>{:%A %H:%M}</span>",
        "format-alt": " {:%Y/%m/%d}",
        "tooltip-format": "<tt><small>{calendar}</small></tt>",
        "calendar": {
            "mode": "month",
            "mode-mon-col": 3,
            "weeks-pos": "right",
            "on-scroll": 1,
            "format": {
                "months": "<span color='#ffead3'><b>{}</b></span>",
                "days": "<span color='#ecc6d9'><b>{}</b></span>",
                "weeks": "<span color='#99ffdd'><b>W{}</b></span>",
                "weekdays": "<span color='#ffcc66'><b>{}</b></span>",
                "today": "<span color='#ff6699'><b><u>{}</u></b></span>"
            }
        },
        "actions": {
            "on-click-right": "mode"
        }
      },

      "network": {
        "format-wifi": "  {essid}",
        "format-ethernet": "󰈀 Wired",
        "format-disconnected": "⚠ Disconnected",
        "tooltip-format": "{ifname}: {ipaddr} | 訊號強度: {signalStrength}%"
      },

      "hyprland/workspaces": { "format": "{name}", "on-click": "activate" },
      "pulseaudio": { "format": "  {volume:>3}%", "format-muted": "󰝟 Muted", "on-click": "pavucontrol" },
      // 💡 {:>2} 保證個位數和十位數佔用的寬度完全一樣，防止任務欄抖動
      "cpu": { "format": "  {usage:>2}%", "interval": 2 },
      "memory": { "format": "  {percentage:>2}%", "interval": 2 },
      "tray": { "icon-size": 16, "spacing": 8 }
    }
  '';

  xdg.configFile."waybar/style.css".text = ''
    * {
        font-family: "JetBrainsMono Nerd Font", "Symbols Nerd Font", "Noto Sans CJK TC", sans-serif;
        font-size: 13px;
        /* 💡 終極防抖：強制數字等寬。1和8佔用相同像素！ */
    }

    window#waybar { background-color: transparent; transition: all 0.3s; }
    window#waybar.hidden { opacity: 0; margin-bottom: -50px; }

    /* 💡 黃金比例圓角長方形，並加上物理慣性的絲滑動畫 */
    .modules-center {
        background: rgba(26, 27, 38, 0.88);
        border: 1px solid rgba(255, 255, 255, 0.12);
        border-radius: 14px; /* 👈 從死圓的20px改為高質感的14px超橢圓 */
        padding: 4px 16px;
        box-shadow: 0 4px 14px rgba(0, 0, 0, 0.6);
        /* 👈 長度改變時，展現果凍般的阻尼絲滑滑動 */
        transition: all 0.4s cubic-bezier(0.25, 1, 0.5, 1); 
    }

    #workspaces, #custom-app-telemetry, #custom-population, #pulseaudio, #network, #cpu, #memory, #custom-jp-day, #clock, #tray {
        margin: 0 6px;
        color: #c0caf5;
    }

    #custom-app-telemetry { color: #2ac3de; font-weight: bold; background: rgba(41, 169, 219, 0.12); padding: 0 10px; border-radius: 10px; }
    #custom-population { font-size: 11px; font-weight: bold; color: #7aa2f7; }
    /* =========================================================================
       ✨ 潛意識級呼吸燈 (Ambient Pulse) - 極緩慢、極微小的擴張
       ========================================================================= */
    /* 刪除 pulse-clock，時鐘不再呼吸 */
    
    @keyframes pulse-getsu {
        0%   { text-shadow: 0 0 2px #b2ebf2, 0 0 6px #80deea; }
        50%  { text-shadow: 0 0 2px #b2ebf2, 0 0 8px #80deea, 0 0 12px #00bcd4; }
        100% { text-shadow: 0 0 2px #b2ebf2, 0 0 6px #80deea; }
    }
    @keyframes pulse-ka {
        0%   { text-shadow: 0 0 2px #ff5252, 0 0 6px #ff1744; }
        50%  { text-shadow: 0 0 3px #ff5252, 0 0 8px #ff1744, 0 0 12px #d50000; }
        100% { text-shadow: 0 0 2px #ff5252, 0 0 6px #ff1744; }
    }
    @keyframes pulse-sui {
        0%   { text-shadow: 0 0 2px #00f0ff, 0 0 6px #00c853; }
        50%  { text-shadow: 0 0 3px #00f0ff, 0 0 8px #00c853, 0 0 12px #009688; }
        100% { text-shadow: 0 0 2px #00f0ff, 0 0 6px #00c853; }
    }
    @keyframes pulse-moku {
        0%   { text-shadow: 0 0 2px #76ff03, 0 0 6px #00e676; }
        50%  { text-shadow: 0 0 3px #76ff03, 0 0 8px #00e676, 0 0 14px #00c853; }
        100% { text-shadow: 0 0 2px #76ff03, 0 0 6px #00e676; }
    }
    @keyframes pulse-kin {
        0%   { text-shadow: 0 0 2px #ffd54f, 0 0 6px #ffb300, 0 0 8px #ff8f00; }
        50%  { text-shadow: 0 0 3px #ffd54f, 0 0 8px #ffb300, 0 0 12px #ff8f00; }
        100% { text-shadow: 0 0 2px #ffd54f, 0 0 6px #ffb300, 0 0 8px #ff8f00; }
    }
    @keyframes pulse-do {
        0%   { text-shadow: 0 0 2px #e0a96d, 0 0 6px #b07d62; }
        50%  { text-shadow: 0 0 3px #e0a96d, 0 0 8px #b07d62, 0 0 12px #7f4f24; }
        100% { text-shadow: 0 0 2px #e0a96d, 0 0 6px #b07d62; }
    }
    @keyframes pulse-nichi {
        0%   { text-shadow: 0 0 2px #ff9800, 0 0 6px #f57c00; }
        50%  { text-shadow: 0 0 3px #ff9800, 0 0 8px #f57c00, 0 0 14px #e65100; }
        100% { text-shadow: 0 0 2px #ff9800, 0 0 6px #f57c00; }
    }

    /* 💡 日本曜日基礎樣式 */
    #custom-jp-day {
        font-weight: bold;
        margin-right: 4px;
        padding: 0 8px; /* 收斂一點 padding 讓它與時鐘靠得更緊湊 */
        transition: all 0.5s ease;
    }

    /* 💡 將動畫週期拉長至 16~20 秒！極其緩慢的能量潮汐 */
    #custom-jp-day.youbi-getsu { color: #e0f7fa; animation: pulse-getsu 18s ease-in-out infinite; }
    #custom-jp-day.youbi-ka    { color: #ff3838; animation: pulse-ka 17s ease-in-out infinite; }
    #custom-jp-day.youbi-sui   { color: #2de2e6; animation: pulse-sui 19s ease-in-out infinite; }
    #custom-jp-day.youbi-moku  { color: #39ff14; animation: pulse-moku 18s ease-in-out infinite; }
    #custom-jp-day.youbi-kin   { color: #fff176; animation: pulse-kin 16s ease-in-out infinite; }
    #custom-jp-day.youbi-do    { color: #d4a373; animation: pulse-do 20s ease-in-out infinite; }
    #custom-jp-day.youbi-nichi { color: #ffa726; animation: pulse-nichi 15s ease-in-out infinite; }

    /* 💡 時鐘回歸純淨：無光暈、無動畫、絕對靜止 */
    #clock {
        color: #e0af68; 
        font-weight: bold;
        margin-left: 2px;
        text-shadow: none; /* 徹底關閉光暈 */
        animation: none;   /* 徹底關閉動畫 */
    }
  '';
}
