{ pkgs, ... }: {
  services = {
    supergfxd.enable = true;
    asusd = {
      enable = true;
      enableUserService = true;
      package = pkgs.unstable.asusctl;
    };
  };
}
