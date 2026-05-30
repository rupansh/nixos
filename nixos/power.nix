{
  # Intel DPTF: lets the platform actively manage thermals/power instead of
  # only reacting at PROCHOT. Recommended for Meteor Lake.
  services.thermald.enable = true;

  # Bias PCIe link power saving harder than the kernel default. Safe on this
  # SoC — Meteor Lake root ports + the dGPU/NVMe all advertise L1.
  boot.kernelParams = [ "pcie_aspm.policy=powersupersave" ];
}
