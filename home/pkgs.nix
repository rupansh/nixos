{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # DE related
    app2unit
    pass
    wl-clipboard
    vesktop
    loupe
    p7zip
    pavucontrol
    brightnessctl
    hyprprop
    gammastep
    nemo-with-extensions

    # utils
    proton-vpn
    vlc
    stremio-linux-shell
    unzip
    brave
    usbutils
    popsicle
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

    # virt
    gnome-boxes
    phodav
    ntfs3g
  ];
}
