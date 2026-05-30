{
  # Intel DPTF: lets the platform actively manage thermals/power instead of
  # only reacting at PROCHOT. Recommended for Meteor Lake.
  services.thermald.enable = true;

  # Bias PCIe link power saving harder than the kernel default. Safe on this
  # SoC — Meteor Lake root ports + the dGPU/NVMe all advertise L1.
  # usbcore.autosuspend=1: USB devices idle for >1s get runtime-suspended,
  # which lets XHCI gate off and is a precondition for S0ix entry.
  boot.kernelParams = [
    "pcie_aspm.policy=powersupersave"
    "usbcore.autosuspend=1"
  ];

  # Enable NetworkManager's wifi power-save (sets wifi.powersave=3 in NM.conf).
  # Without this, iwlwifi runs CNVi at full power and blocks S0ix.
  networking.networkmanager.wifi.powersave = true;

  # iwlwifi/iwlmvm: enable runtime power save and switch to the low-power
  # scheme (1=performance, 2=balanced default, 3=low-power). uapsd_disable=0
  # keeps UAPSD so latency under PM stays usable.
  # snd_hda_intel: lets the HDA controller runtime-suspend after 1s idle,
  # which lets the audio DSPs (DSP0/1/2) power-gate — another S0ix gate.
  # iwlmvm power_scheme: 1=performance, 2=balanced default, 3=lowpower.
  # We tried 3 — the AX211 firmware NMI'd ~30 min in and self-reset; revert to
  # 2 (the upstream default) to keep iwlwifi.power_save=Y's benefit without
  # tripping the lowpower-scheme firmware bug.
  boot.extraModprobeConfig = ''
    options iwlwifi power_save=Y uapsd_disable=0
    options iwlmvm power_scheme=2
  '';
}
