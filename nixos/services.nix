{ lib, ... }: {
  services.gvfs.enable = true;
  services.udisks2.enable = true;
  services.upower.enable = true;

  services.avahi = {
    enable = true;
    nssmdns4 = true;
  };

  services.tailscale.enable = true;

  systemd.services.nvidia-container-toolkit-cdi-generator = {
    wantedBy = lib.mkForce [ ];
    before = [ "docker.service" ];
  };

  services.getty = {
    autologinOnce = true;
    autologinUser = "rupansh";
  };
}
