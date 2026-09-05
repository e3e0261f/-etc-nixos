{ pkgs, ... }:

let
  # 1. 活動視窗遙測探針 (具備 Socket 自癒能力)
  activeAppTelemetry = pkgs.writeScriptBin "active-app-telemetry" ''
    #!${pkgs.python3}/bin/python3
    import json
    import os
    import subprocess
    import time

    STATE_FILE = "/tmp/hypr_active_app_telemetry.json"

    def fix_hypr_env():
        uid = os.getuid()
        hypr_dir = f"/run/user/{uid}/hypr"
        current_his = os.getenv("HYPRLAND_INSTANCE_SIGNATURE")

        if current_his and os.path.exists(f"{hypr_dir}/{current_his}/.socket.sock"):
            return

        try:
            if os.path.exists(hypr_dir):
                dirs = [
                    d for d in os.listdir(hypr_dir)
                    if os.path.exists(os.path.join(hypr_dir, d, ".socket.sock"))
                ]
                if dirs:
                    dirs.sort(key=lambda d: os.path.getmtime(os.path.join(hypr_dir, d)), reverse=True)
                    os.environ["HYPRLAND_INSTANCE_SIGNATURE"] = dirs[0]
        except Exception:
            pass

    def get_active_window():
        fix_hypr_env()
        try:
            env = os.environ.copy()
            out = subprocess.check_output(["${pkgs.hyprland}/bin/hyprctl", "activewindow", "-j"], text=True, env=env)
            data = json.loads(out)
            if not data or not data.get("pid"):
                return None
            return data
        except Exception:
            return None

    def get_proc_stats(pid):
        rss_mb = 0
        try:
            with open(f"/proc/{pid}/status", "r") as f:
                for line in f:
                    if line.startswith("VmRSS:"):
                        rss_mb = int(line.split()[1]) // 1024
                        break
        except Exception:
            pass

        sockets = 0
        try:
            fd_dir = f"/proc/{pid}/fd"
            for entry in os.listdir(fd_dir):
                try:
                    target = os.readlink(os.path.join(fd_dir, entry))
                    if target.startswith("socket:"):
                        sockets += 1
                except Exception:
                    continue
        except Exception:
            pass

        rchar, wchar = 0, 0
        try:
            with open(f"/proc/{pid}/io", "r") as f:
                for line in f:
                    if line.startswith("rchar:"):
                        rchar = int(line.split()[1])
                    elif line.startswith("wchar:"):
                        wchar = int(line.split()[1])
        except Exception:
            pass

        return rss_mb, sockets, rchar, wchar

    def format_bytes(b):
        if b < 1024:
            return f"{int(b)}B"
        elif b < 1024 * 1024:
            return f"{b/1024:.1f}K"
        elif b < 1024 * 1024 * 1024:
            return f"{b/(1024*1024):.1f}M"
        else:
            return f"{b/(1024*1024*1024):.1f}G"

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
                with open(STATE_FILE, "r") as f:
                    state = json.load(f)
            except Exception:
                state = {}

        history = state.get(str(pid), [])
        history.append([now, rchar, wchar])
        history = [h for h in history if now - h[0] <= 65]
        state[str(pid)] = history
        state = {k: v for k, v in state.items() if os.path.exists(f"/proc/{k}")}

        try:
            with open(STATE_FILE, "w") as f:
                json.dump(state, f)
        except Exception:
            pass

        down_rate_str = "0B/s"
        up_rate_str = "0B/s"
        if len(history) >= 2:
            t_diff = history[-1][0] - history[0][0]
            if t_diff > 0.8:
                r_diff = max(0, history[-1][1] - history[0][1])
                w_diff = max(0, history[-1][2] - history[0][2])
                down_rate_str = f"{format_bytes(r_diff / t_diff)}/s"
                up_rate_str = f"{format_bytes(w_diff / t_diff)}/s"

        text = f"{app_name}  󰍛 {rss_mb}M  󰡉 {sockets}  ↓ {down_rate_str} ↑ {up_rate_str}"

        w_class = win.get("class", "N/A")
        w_init_class = win.get("initialClass", "N/A")
        w_title = win.get("title", "N/A")
        w_init_title = win.get("initialTitle", "N/A")
        w_address = win.get("address", "N/A")
        w_floating = "是 (True)" if win.get("floating") else "否 (False)"
        w_ws = win.get("workspace", {}).get("name", "N/A")
        w_xwayland = "是 (X11)" if win.get("xwayland") else "否 (原生 Wayland)"

        tooltip = (
            f"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
            f"  🪟 Hyprland 視窗規則屬性查詢\n"
            f"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
            f"  • class        : {w_class}\n"
            f"  • initialClass : {w_init_class}\n"
            f"  • title        : {w_title}\n"
            f"  • initialTitle : {w_init_title}\n"
            f"  • address      : {w_address}\n"
            f"  • PID          : {pid}\n"
            f"  • 工作區 (WS)  : {w_ws}\n"
            f"  • 浮動狀態     : {w_floating}\n"
            f"  • 顯示協議     : {w_xwayland}\n"
            f"───────────────────────────────────\n"
            f"  📊 即時資源遙測\n"
            f"  • 物理記憶體   : {rss_mb} MB\n"
            f"  • 活躍 Socket  : {sockets} 個\n"
            f"  • 近 1 分鐘吞吐: ↓ {down_rate_str} | 上傳 {up_rate_str}\n"
            f"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
            f"💡 常用規則範例:\n"
            f"  windowrulev2 = float, class:^({w_class})$"
        )

        print(json.dumps({"text": text, "tooltip": tooltip}))

    if __name__ == "__main__":
        main()
  '';

  # 2. 日本曜日腳本 (強制英文星期)
  jpDayScript = pkgs.writeShellScriptBin "jp-day" ''
    #!/bin/bash
    W=$(date +%V)
    D=$(date +%u)
    E=$(LC_TIME=C date +%A)
    case $D in
      1) J="月曜"; C="youbi-getsu";;
      2) J="火曜"; C="youbi-ka";;
      3) J="水曜"; C="youbi-sui";;
      4) J="木曜"; C="youbi-moku";;
      5) J="金曜"; C="youbi-kin";;
      6) J="土曜"; C="youbi-do";;
      7) J="日曜"; C="youbi-nichi";;
    esac
    
    TEXT="$W <span rise='-1500'>$J</span> $E"
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
      "height": 45,
      "width": 1200,
      "margin-bottom": 25,
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
        "format": "{:%H:%M}",
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
        "format-wifi": "󰤨  {essid}",
        "format-ethernet": "󰈀 Wired",
        "format-disconnected": "󰤭 Disconnected",
        "tooltip-format": "{ifname}: {ipaddr} | 訊號強度: {signalStrength}%"
      },

      "hyprland/workspaces": {
        "format": "{name}",
        "on-click": "activate",
        "all-outputs": true,
        "sort-by-number": true
      },

      "pulseaudio": { "format": "󰕾 {volume}%", "format-muted": "󰝟 Muted", "on-click": "pavucontrol" },
      "cpu": { "format": "󰻠 {usage}%", "interval": 2 },
      "memory": { "format": "󰍛 {percentage}%", "interval": 2 },
      "tray": { "icon-size": 16, "spacing": 8 }
    }
  '';

  xdg.configFile."waybar/style.css".text = ''
    * {
        font-family: "JetBrainsMono Nerd Font", "Symbols Nerd Font", "Noto Sans CJK TC", sans-serif;
        font-size: 13px;
    }

    window#waybar { background-color: transparent; transition: all 0.3s; }
    window#waybar.hidden { opacity: 0; margin-bottom: -50px; }

    /* 🧊 3D 黑色水晶玻璃板切片 */
    .modules-center {
        background: linear-gradient(180deg, rgba(42, 46, 70, 0.62) 0%, rgba(12, 13, 22, 0.88) 100%);
        border-top: 1px solid rgba(255, 255, 255, 0.45);
        border-left: 1px solid rgba(255, 255, 255, 0.22);
        border-right: 1px solid rgba(0, 0, 0, 0.5);
        border-bottom: 3px solid rgba(0, 0, 0, 0.88);
        border-radius: 14px;
        padding: 4px 18px;
        box-shadow:
            inset 0 1px 2px rgba(255, 255, 255, 0.32),
            inset 0 -2px 4px rgba(0, 0, 0, 0.75),
            0 10px 30px rgba(0, 0, 0, 0.85);
        transition: all 0.4s cubic-bezier(0.25, 1, 0.5, 1);
    }

    #workspaces, #custom-app-telemetry, #custom-population, #pulseaudio, #network, #cpu, #memory, #custom-jp-day, #clock, #tray {
        margin: 0 6px;
        color: #e0e6ff;
    }

    #workspaces button {
        padding: 1px 9px;
        margin: 0 3px;
        border-radius: 8px;
        color: #6c7086;
        background-color: transparent;
        transition: all 0.3s ease;
    }

    #workspaces button.active {
        color: #ffffff;
        background-color: rgba(255, 255, 255, 0.12);
        border: 1px solid rgba(255, 255, 255, 0.35);
        box-shadow: inset 0 1px 1px rgba(255, 255, 255, 0.25), 0 0 10px rgba(255, 255, 255, 0.2);
        font-weight: bold;
    }

    #workspaces button:hover {
        color: #ffffff;
        background-color: rgba(255, 255, 255, 0.08);
    }

    #custom-app-telemetry {
        color: #2ac3de;
        font-weight: bold;
        background-color: rgba(41, 169, 219, 0.14);
        border: 1px solid rgba(42, 195, 222, 0.28);
        padding: 0 10px;
        border-radius: 10px;
    }

    #custom-population { font-size: 11px; font-weight: bold; color: #a6adc8; }

    /* 💡 修正：完全使用標準 GTK3 語法，移除 !important */
    #custom-jp-day {
        font-weight: bold;
        margin-right: 4px;
        padding: 0 6px;
        border: 0;
        background-color: transparent;
        background-image: none;
        transition: all 0.5s ease;
    }

    #custom-jp-day.youbi-getsu { color: #e0f7fa; text-shadow: 0 0 5px #b2ebf2, 0 0 15px #80deea, 0 0 25px #00bcd4; box-shadow: 0 0 25px 6px rgba(0, 188, 212, 0.25); animation: pulse-getsu 18s ease-in-out infinite; }
    #custom-jp-day.youbi-ka    { color: #ff3838; text-shadow: 0 0 5px #ff5252, 0 0 15px #ff1744, 0 0 25px #d50000; box-shadow: 0 0 25px 6px rgba(255, 23, 68, 0.28); animation: pulse-ka 17s ease-in-out infinite; }
    #custom-jp-day.youbi-sui   { color: #2de2e6; text-shadow: 0 0 5px #00f0ff, 0 0 15px #00c853, 0 0 25px #009688; box-shadow: 0 0 25px 6px rgba(0, 200, 83, 0.25); animation: pulse-sui 19s ease-in-out infinite; }
    #custom-jp-day.youbi-moku  { color: #39ff14; text-shadow: 0 0 5px #76ff03, 0 0 15px #00e676, 0 0 25px #00c853; box-shadow: 0 0 25px 6px rgba(0, 230, 118, 0.28); animation: pulse-moku 18s ease-in-out infinite; }
    #custom-jp-day.youbi-kin   { color: #fff176; text-shadow: 0 0 5px #ffd54f, 0 0 15px #ffb300, 0 0 25px #ff8f00; box-shadow: 0 0 25px 6px rgba(255, 179, 0, 0.3); animation: pulse-kin 16s ease-in-out infinite; }
    #custom-jp-day.youbi-do    { color: #f8c291; text-shadow: 0 0 5px #e0a96d, 0 0 15px rgba(212, 163, 115, 0.7), 0 0 28px rgba(212, 163, 115, 0.4); box-shadow: 0 0 25px 6px rgba(212, 163, 115, 0.28); animation: pulse-do 18s ease-in-out infinite; }
    #custom-jp-day.youbi-nichi { color: #ffa726; text-shadow: 0 0 5px #ff9800, 0 0 15px #f57c00, 0 0 28px #e65100; box-shadow: 0 0 25px 6px rgba(245, 124, 0, 0.32); animation: pulse-nichi 15s ease-in-out infinite; }

    @keyframes pulse-getsu { 0% {text-shadow: 0 0 2px #b2ebf2;} 50% {text-shadow: 0 0 3px #b2ebf2, 0 0 8px #80deea;} 100% {text-shadow: 0 0 2px #b2ebf2;} }
    @keyframes pulse-ka    { 0% {text-shadow: 0 0 2px #ff5252;} 50% {text-shadow: 0 0 3px #ff5252, 0 0 8px #ff1744;} 100% {text-shadow: 0 0 2px #ff5252;} }
    @keyframes pulse-sui   { 0% {text-shadow: 0 0 2px #00f0ff;} 50% {text-shadow: 0 0 3px #00f0ff, 0 0 8px #00c853;} 100% {text-shadow: 0 0 2px #00f0ff;} }
    @keyframes pulse-moku  { 0% {text-shadow: 0 0 2px #76ff03;} 50% {text-shadow: 0 0 3px #76ff03, 0 0 8px #00e676;} 100% {text-shadow: 0 0 2px #76ff03;} }
    @keyframes pulse-kin   { 0% {text-shadow: 0 0 2px #ffd54f;} 50% {text-shadow: 0 0 3px #ffd54f, 0 0 8px #ffb300;} 100% {text-shadow: 0 0 2px #ffd54f;} }
    @keyframes pulse-do    { 0% {text-shadow: 0 0 2px #e0a96d;} 50% {text-shadow: 0 0 3px #e0a96d, 0 0 8px #b07d62;} 100% {text-shadow: 0 0 2px #e0a96d;} }
    @keyframes pulse-nichi { 0% {text-shadow: 0 0 2px #ff9800;} 50% {text-shadow: 0 0 3px #ff9800, 0 0 8px #f57c00;} 100% {text-shadow: 0 0 2px #ff9800;} }

    #clock { color: #e0e6ff; font-weight: bold; margin-left: 2px; }
  '';
}
