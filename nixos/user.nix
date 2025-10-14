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
        "podman"
      ];
      packages = [ ];
    };
  };

  nix.settings.trusted-users = [ "rupansh" ];
}
