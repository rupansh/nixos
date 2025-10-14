{ ... }: {
  # ATK HUB for VXE MAD R
  services.udev.extraRules = ''
    KERNEL=="hidraw*", ATTRS{idVendor}=="373b", MODE="0666"
  '';
}
