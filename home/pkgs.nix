{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # DE related
    unstable.app2unit
    pass
    wl-clipboard
    vesktop
    hyprpaper
    loupe
    p7zip
    hyprshot
    pavucontrol
    brightnessctl
    hyprprop
    gammastep
    nemo-with-extensions

    # utils
    protonvpn-gui
    vlc
    stremio
    unzip
    brave
    usbutils
    popsicle
    spotify
    btop
    upscayl
    rclone

    # dev
    nil
    nixfmt-rfc-style
    devenv
    unstable.claude-code
  ];
}
