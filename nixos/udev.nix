{ ... }: {
  services.udev.extraRules = ''
    # ATK HUB for VXE MAD R
    KERNEL=="hidraw*", ATTRS{idVendor}=="373b", MODE="0666"

    # Enable PCI runtime power management for the integrated CNVi WiFi.
    # Without this the controller stays in D0 and pch_ip_power_gating_status
    # keeps CNVI "On", which blocks S0ix entry on Meteor Lake.
    # 8086:7e40 = Meteor Lake PCH CNVi WiFi.
    # ACTION=="bind": fire after iwlwifi binds and (re)sets power/control=on,
    # not at the earlier "add" phase where the assignment gets clobbered.
    ACTION=="bind", SUBSYSTEM=="pci", ATTR{vendor}=="0x8086", ATTR{device}=="0x7e40", ATTR{power/control}="auto"
  '';
}
