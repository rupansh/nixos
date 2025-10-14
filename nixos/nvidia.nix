{
  hardware.graphics.enable = true;
  services.xserver.videoDrivers = [
    "modesetting"
    "nvidia"
  ];
  hardware.nvidia = {
    open = true;
    prime = {
      offload.enable = true;
      offload.enableOffloadCmd = true;
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
    powerManagement = {
      enable = true;
      finegrained = true;
    };
    dynamicBoost.enable = true;
  };

  hardware.nvidia-container-toolkit.enable = true;

  boot.kernelParams = [
    "i915.enable_dpcd_backlight=1"
    "nvidia.NVreg_EnableBacklightHandler=0"
    "nvidia.NVReg_RegistryDwords=EnableBrightnessControl=0"
  ];
}
