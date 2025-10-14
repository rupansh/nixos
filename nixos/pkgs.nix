{ pkgs, ... }:
{

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    vim
    steam-run
    gparted
    xkeyboard_config
  ];
}
