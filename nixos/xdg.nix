{ pkgs, ... }:
{
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
    config = {
      hyprland.default = [
        "hyprland"
        "gtk"
      ];
    };
  };
}
