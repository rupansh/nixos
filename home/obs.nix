{ pkgs, ... }:
{
  programs.obs-studio = {
    enable = true;
    plugins = with pkgs.obs-studio-plugins; [
      # wlroots-based screen / window capture. Hyprland's xdg-desktop-portal
      # also exposes a PipeWire "Screen Capture (PipeWire)" source built into
      # OBS, but wlrobs gives a lighter direct path when the portal route
      # is flaky.
      wlrobs
      # Per-application audio source via PipeWire (route just Discord/game
      # audio etc., instead of the whole sink monitor).
      obs-pipewire-audio-capture
      # On-the-fly selfie background removal — useful for webcam scenes.
      obs-backgroundremoval
    ];
  };
  # Note: OBS's virtual-camera feature requires the v4l2loopback kernel
  # module, which home-manager can't load. If needed later, add
  # `boot.extraModulePackages = [ config.boot.kernelPackages.v4l2loopback ];`
  # and `boot.kernelModules = [ "v4l2loopback" ];` to nixos/.
}
