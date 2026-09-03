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
  programs.waybar = {
    enable = true;
    systemd = {
      enable = true;
      targets = [ "graphical-session.target" ];
    };
  };

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
        "format": "<span rise='0'>{:%A}</span> <span rise='0'>{:%H:%M}</span>",
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
        font-variant-numeric: tabular-nums; 
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

    /* 呼吸燈動畫 */
    @keyframes pulse-clock { 0% {text-shadow: 0 0 2px #e0af68, 0 0 4px #e0af68;} 50% {text-shadow: 0 0 4px #e0af68, 0 0 12px #ffb300, 0 0 20px #ff9800;} 100% {text-shadow: 0 0 2px #e0af68, 0 0 4px #e0af68;} }
    @keyframes pulse-getsu { 0% {text-shadow: 0 0 2px #b2ebf2;} 50% {text-shadow: 0 0 5px #b2ebf2, 0 0 15px #80deea, 0 0 22px #00bcd4;} 100% {text-shadow: 0 0 2px #b2ebf2;} }
    @keyframes pulse-ka { 0% {text-shadow: 0 0 2px #ff5252;} 50% {text-shadow: 0 0 5px #ff5252, 0 0 15px #ff1744, 0 0 24px #d50000;} 100% {text-shadow: 0 0 2px #ff5252;} }
    @keyframes pulse-sui { 0% {text-shadow: 0 0 2px #00f0ff;} 50% {text-shadow: 0 0 5px #00f0ff, 0 0 15px #00c853, 0 0 22px #009688;} 100% {text-shadow: 0 0 2px #00f0ff;} }
    @keyframes pulse-moku { 0% {text-shadow: 0 0 2px #76ff03;} 50% {text-shadow: 0 0 6px #76ff03, 0 0 16px #00e676, 0 0 25px #00c853;} 100% {text-shadow: 0 0 2px #76ff03;} }
    @keyframes pulse-kin { 0% {text-shadow: 0 0 2px #ffd54f;} 50% {text-shadow: 0 0 6px #ffd54f, 0 0 16px #ffb300, 0 0 26px #ff8f00;} 100% {text-shadow: 0 0 2px #ffd54f;} }
    @keyframes pulse-do { 0% {text-shadow: 0 0 2px #e0a96d;} 50% {text-shadow: 0 0 5px #e0a96d, 0 0 14px #b07d62, 0 0 20px #7f4f24;} 100% {text-shadow: 0 0 2px #e0a96d;} }
    @keyframes pulse-nichi { 0% {text-shadow: 0 0 2px #ff9800;} 50% {text-shadow: 0 0 6px #ff9800, 0 0 16px #f57c00, 0 0 28px #e65100;} 100% {text-shadow: 0 0 2px #ff9800;} }

    #custom-jp-day { font-weight: bold; margin-right: 4px; padding: 0 10px; transition: all 0.5s ease; }
    #custom-jp-day.youbi-getsu { color: #e0f7fa; animation: pulse-getsu 4s ease-in-out infinite; }
    #custom-jp-day.youbi-ka    { color: #ff3838; animation: pulse-ka 3.5s ease-in-out infinite; }
    #custom-jp-day.youbi-sui   { color: #2de2e6; animation: pulse-sui 4.5s ease-in-out infinite; }
    #custom-jp-day.youbi-moku  { color: #39ff14; animation: pulse-moku 4s ease-in-out infinite; }
    #custom-jp-day.youbi-kin   { color: #fff176; animation: pulse-kin 3.8s ease-in-out infinite; }
    #custom-jp-day.youbi-do    { color: #d4a373; animation: pulse-do 5s ease-in-out infinite; }
    #custom-jp-day.youbi-nichi { color: #ffa726; animation: pulse-nichi 3s ease-in-out infinite; }

    #clock { color: #e0af68; font-weight: bold; margin-left: 2px; animation: pulse-clock 4s ease-in-out infinite; }
    #network { color: #9ece6a; }
    #cpu { color: #7dcfff; }
    #memory { color: #bb9af7; }
    #pulseaudio { color: #7aa2f7; }
  '';
}
