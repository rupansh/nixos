{ pkgs, ... }: {

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    libxkbcommon
    libGL
    qt6.qtwayland
    wayland
    libx11
    libxscrnsaver
    libxcomposite
    libxcursor
    libxdamage
    libxext
    libxfixes
    libxi
    libxrandr
    libxrender
    libxtst
    libxcb
    libxkbfile
    libxshmfence
  ];
}
