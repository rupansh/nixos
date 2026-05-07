{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # DE related
    app2unit
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
    proton-vpn
    vlc
    #stremio
    unzip
    brave
    usbutils
    popsicle
    spotify
    btop
    upscayl
    rclone
    dmidecode
    telegram-desktop
    hwloc
    rustdesk-flutter
    qbittorrent

    # dev
    nil
    nixfmt
    devenv
  ];
}
