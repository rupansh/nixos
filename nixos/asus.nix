{ pkgs, ... }: {
  services = {
    supergfxd.enable = true;
    asusd = {
      enable = true;
      package = pkgs.asusctl;
    };
  };
}
