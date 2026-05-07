{ lib, pkgs, ... }:
{
  programs.firefox = {
    enable = true;
    configPath = ".mozilla/firefox";
  };

  programs.alacritty = {
    enable = true;
    package = pkgs.alacritty;
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
    shellWrapperName = "y";
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

  programs.lutris.enable = true;

  programs.gh = {
    enable = true;
    settings.git_protocol = "ssh";
  };
}
