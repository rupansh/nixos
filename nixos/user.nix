{ pkgs, ... }:
{
  users = {
    users.rupansh = {
      isNormalUser = true;
      description = "Rupansh";
      extraGroups = [
        "networkmanager"
        "input"
        "wheel"
        "docker"
      ];
      packages = [ ];
    };
  };

  nix.settings.trusted-users = [ "rupansh" ];
}
