{ pkgs, ... }: {
  services = {
    asusd = {
      enable = true;
      package = pkgs.asusctl;
    };
    supergfxd = {
      enable = true;
      # No display-manager.service on this host (tty1 autologin + uwsm), so the
      # runtime "stop DM, unload nvidia, restart DM" mode-switch dance errors out
      # and never persists the new mode. always_reboot=true makes mode changes
      # apply on the next boot — cleanly, with no live session to evict.
      # Since this option makes /etc/supergfxd.conf a read-only nix-store symlink,
      # the GUI/CLI can no longer write back: switch modes by editing `mode` here
      # and rebuilding.
      settings = {
        mode = "Integrated";
        vfio_enable = false;
        vfio_save = false;
        always_reboot = true;
        no_logind = false;
        logout_timeout_s = 180;
        hotplug_type = "Asus";
      };
    };
  };

  programs.rog-control-center = {
    enable = true;
    autoStart = true;
  };

  # supergfxd uses lsof to enumerate/kill processes holding /dev/nvidia* before
  # unloading the driver; it warns at mode-switch time when the binary is missing.
  environment.systemPackages = [ pkgs.lsof ];
}
