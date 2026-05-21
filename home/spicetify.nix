{ pkgs, ... }:
let
  # Aurora ships prebuilt extension JS only in its release tarball — the repo's
  # extensions/ dir holds source .ts and a .gitkeep, no compiled .js. Pulling
  # the release tarball avoids needing typescript/esbuild at build time.
  auroraRelease = pkgs.stdenvNoCC.mkDerivation {
    pname = "aurora-spicetify";
    version = "0.1.8";
    src = pkgs.fetchurl {
      url = "https://github.com/ayamdobhal/aurora/releases/download/v0.1.8/aurora.tar.gz";
      hash = "sha256-J6nxOr3e22LdTfWqlfqG4vIrMlt+MqsI6JXykHDkYOI=";
    };
    dontConfigure = true;
    dontBuild = true;
    sourceRoot = ".";
    installPhase = ''
      mkdir -p $out
      cp -r theme $out/theme
      cp -r extensions $out/extensions
    '';
  };

  mkExt = name: {
    src = "${auroraRelease}/extensions";
    inherit name;
  };
in
{
  programs.spicetify = {
    enable = true;

    theme = {
      name = "aurora";
      src = "${auroraRelease}/theme";
      # Aurora extracts its accent from album art at runtime, so we don't want
      # spicetify-nix's color.ini → CSS-variable substitution clobbering the
      # theme's own bootstrap colour values.
      replaceColors = false;
      injectCss = true;
      injectThemeJs = true;
      overwriteAssets = false;
    };

    enabledExtensions = map mkExt [
      "layout.js"
      "dynamic-theme.js"
      "right-panel.js"
      "lyrics.js"
      "command-palette.js"
      "shortcuts.js"
      "top-bar.js"
      "miniplayer.js"
    ];
  };
}
