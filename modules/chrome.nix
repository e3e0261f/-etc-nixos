# /etc/nixos/modules/chrome.nix
{ pkgs, ... }:

let
  # ⭐️ 修正：移除與視訊解碼衝突的 --use-angle=vulkan 和 --enable-zero-copy
  # 保留純血 Vulkan 加速、GPU 柵格化與原生 Wayland，保證影片正常播放！
  vulkanFlags = ''
    --enable-features=Vulkan
    --ozone-platform=wayland
    --enable-gpu-rasterization
  '';
in
{
  xdg.configFile."chrome-flags.conf".text = vulkanFlags;
  xdg.configFile."chromium-flags.conf".text = vulkanFlags;
}
