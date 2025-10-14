{ osConfig, ... }:
{
  imports = [
    ./hyprland.nix
    ./modules.nix
    ./pkgs.nix
    ./services.nix
    ./fish.nix
    ./gpg.nix
    ./gtk-theme.nix
    ./vscode.nix
    ./walker.nix
    ./git.nix
    ./waybar
    ./swaync.nix
    ./claude-code.nix
  ];

  home = {
    username = "rupansh";
    homeDirectory = "/home/rupansh";
    stateVersion = "25.05";
    sessionVariables = {
      "APP2UNIT_SLICES" = "a=app-graphical.slice b=background-graphical.slice s=session-graphical.slice";
      "APP2UNIT_TYPE" = "scope";
      "XKB_CONFIG_ROOT" = "${osConfig.services.xserver.xkb.dir}";
    };
  };

  fonts.fontconfig.enable = true;
}
