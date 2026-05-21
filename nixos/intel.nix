{ pkgs, ... }:
{
  hardware.graphics.extraPackages = with pkgs; [
    intel-media-driver
    # oneVPL GPU runtime — required for QSV (e.g. OBS hardware encoder).
    # intel-media-driver alone only provides the VA-API path.
    vpl-gpu-rt
  ];
}
