{ config, pkgs, ... }:
{
  home.pointerCursor = {
    enable = true;
    gtk.enable = true;
    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Ice";
    size = 16;
  };

  gtk = {
    enable = true;
    theme = {
      # closest surviving match to the removed Nordic theme after the
      # nixpkgs gtk-engine-murrine purge (prebuilt, no murrine dependency)
      package = pkgs.catppuccin-gtk;
      name = "catppuccin-frappe-blue-standard";
    };

    iconTheme = {
      package = pkgs.vimix-icon-theme;
      name = "Vimix-doder-dark";
    };

    font = {
      name = "Noto Sans";
      size = 11;
    };

    gtk3.extraConfig.gtk-application-prefer-dark-theme = true;
    gtk4.extraConfig.gtk-application-prefer-dark-theme = 1;
    gtk4.theme = config.gtk.theme;
  };
}
