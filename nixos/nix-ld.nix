{ pkgs, ... }: {

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    libxkbcommon
    libGL
    qt6.qtwayland
    wayland
    xorg.libX11
    xorg.libXScrnSaver
    xorg.libXcomposite
    xorg.libXcursor
    xorg.libXdamage
    xorg.libXext
    xorg.libXfixes
    xorg.libXi
    xorg.libXrandr
    xorg.libXrender
    xorg.libXtst
    xorg.libxcb
    xorg.libxkbfile
    xorg.libxshmfence
  ];
}
