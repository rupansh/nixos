{ pkgs, ... }:
{

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    vim
    podman-compose
    steam-run
    gparted
    xkeyboard_config
  ];
}
