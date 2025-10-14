{ lib, pkgs, ... }:
{
  programs.firefox.enable = true;

  programs.alacritty = {
    enable = true;
    package = pkgs.unstable.alacritty;
    settings = {
      window = {
        decorations = "None";
        opacity = 0.8;
      };
      terminal = {
        shell = "${lib.getExe pkgs.fish}";
      };
    };
  };

  programs.yazi = {
    enable = true;
    enableFishIntegration = true;
    plugins = {
      mount = pkgs.yaziPlugins.mount;
    };
    keymap = {
      mgr.prepend_keymap = [
        {
          run = "plugin mount";
          on = "M";
        }
      ];
    };
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
