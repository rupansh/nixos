{ lib, pkgs, caelestia-shell, ... }:
let
  inherit (pkgs.stdenv.hostPlatform) system;

  # Shrink the Performance and Weather tabs of the dashboard by patching the
  # hardcoded minimum widths in modules/dashboard/*.qml. None of these
  # numbers are exposed via shell-tokens.json — they're inline magic ints.
  # Recheck after caelestia updates; if the matching string changes upstream
  # `--replace-fail` will surface that loudly on the next rebuild.
  caelestiaShell =
    caelestia-shell.packages.${system}.with-cli.overrideAttrs (old: {
      # Order matters: substituteInPlace runs --replace-fail left-to-right
      # against the in-place file, so a later substitution will catch the
      # output of an earlier one. The Layout.minimumWidth chain (Network
      # 200→160, then Memory/Storage 250→200) is the trap — Network must
      # land first or the new 200s from Memory/Storage get rewritten to 160.
      postPatch = (old.postPatch or "") + ''
        substituteInPlace modules/dashboard/Performance.qml \
          --replace-fail \
            "minWidth: 400 + 400 + Tokens.spacing.normal + 120 + Tokens.padding.large * 2" \
            "minWidth: 280 + 280 + Tokens.spacing.normal + 100 + Tokens.padding.large * 2" \
          --replace-fail "Layout.minimumWidth: 400" "Layout.minimumWidth: 280" \
          --replace-fail "Layout.minimumWidth: 200" "Layout.minimumWidth: 160" \
          --replace-fail "Layout.minimumWidth: 250" "Layout.minimumWidth: 200" \
          --replace-fail "Layout.preferredHeight: 150" "Layout.preferredHeight: 120" \
          --replace-fail "Layout.preferredHeight: 220" "Layout.preferredHeight: 180" \
          --replace-fail "Layout.preferredWidth: 120" "Layout.preferredWidth: 100"
        substituteInPlace modules/dashboard/WeatherTab.qml \
          --replace-fail \
            "implicitWidth: layout.implicitWidth > 800 ? layout.implicitWidth : 840" \
            "implicitWidth: layout.implicitWidth > 500 ? layout.implicitWidth : 540"
      '';
    });
  # Seed the built-in `gruvbox/soft/dark` scheme — the only shipped palette
  # with a warm orange primary (`ffb878`) and warm dark surfaces (`18120e`).
  # Using a real built-in name means `caelestia wallpaper` /
  # `caelestia scheme set` can re-read this from the CLI's data dir without
  # crashing. Seeded only if scheme.json doesn't exist yet, so any
  # launcher-driven scheme/mode toggles persist across rebuilds.
  warmScheme = {
    name = "gruvbox";
    flavour = "soft";
    mode = "dark";
    variant = "tonalspot";
    colours = {
      primary_paletteKeyColor = "a46a32";
      secondary_paletteKeyColor = "907156";
      tertiary_paletteKeyColor = "767c33";
      neutral_paletteKeyColor = "7e756f";
      neutral_variant_paletteKeyColor = "847468";

      background = "18120e";
      onBackground = "ece0d9";
      surface = "18120e";
      surfaceDim = "18120e";
      surfaceBright = "3f3833";
      surfaceContainerLowest = "120d09";
      surfaceContainerLow = "201a16";
      surfaceContainer = "241e1a";
      surfaceContainerHigh = "2f2924";
      surfaceContainerHighest = "3a332e";
      onSurface = "ece0d9";
      surfaceVariant = "52443a";
      onSurfaceVariant = "d6c3b5";
      inverseSurface = "ece0d9";
      inverseOnSurface = "362f2a";
      outline = "9f8e81";
      outlineVariant = "52443a";
      shadow = "000000";
      scrim = "000000";
      surfaceTint = "ffb878";

      primary = "ffb878";
      onPrimary = "4c2700";
      primaryContainer = "c28349";
      onPrimaryContainer = "0d0400";
      inversePrimary = "87521c";
      secondary = "e5bfa1";
      onSecondary = "432b16";
      secondaryContainer = "5c412a";
      onSecondaryContainer = "d3ae90";
      # gruvbox/soft/dark ships these as yellow-green (c6cc7a / 90964a) which
      # bleeds into the bar clock/date glyphs (m3tertiary). Swapped to a warm
      # amber so the bar reads consistent with the rest of the palette.
      tertiary = "ffc18f";
      onTertiary = "4c2700";
      tertiaryContainer = "8c5400";
      onTertiaryContainer = "ffdcc1";
      error = "ffb4ab";
      onError = "690005";
      errorContainer = "93000a";
      onErrorContainer = "ffdad6";

      primaryFixed = "ffdcc1";
      primaryFixedDim = "ffb878";
      onPrimaryFixed = "2e1500";
      onPrimaryFixedVariant = "6b3b04";
      secondaryFixed = "ffdcc1";
      secondaryFixedDim = "e5bfa1";
      onSecondaryFixed = "2b1704";
      onSecondaryFixedVariant = "5c412a";
      tertiaryFixed = "ffdcc1";
      tertiaryFixedDim = "ffc18f";
      onTertiaryFixed = "2e1500";
      onTertiaryFixedVariant = "6b3b04";

      term0 = "353433";
      term1 = "e17300";
      term2 = "ffc071";
      term3 = "ffe0c6";
      term4 = "b9ab66";
      term5 = "ed9562";
      term6 = "f4c16d";
      term7 = "ebd4c1";
      term8 = "b29f91";
      term9 = "ff8a20";
      term10 = "ffd6a8";
      term11 = "fff2e8";
      term12 = "d7be91";
      term13 = "fcad7e";
      term14 = "ffd497";
      term15 = "ffffff";

      rosewater = "ffeee5";
      flamingo = "fedbc7";
      pink = "ffd4c1";
      mauve = "ffac8e";
      red = "fe9c5e";
      maroon = "f5af83";
      peach = "ffc18f";
      yellow = "ffeee1";
      green = "ffdaa5";
      teal = "ffdb92";
      sky = "e1df87";
      sapphire = "b3d27e";
      blue = "ffa2bd";
      lavender = "ffbcbb";

      klink = "bf6ba0";
      klinkSelection = "bf6ba0";
      kvisited = "cc6232";
      kvisitedSelection = "cc6232";
      knegative = "d66a00";
      knegativeSelection = "d66900";
      kneutral = "ff8d00";
      kneutralSelection = "ff8d06";
      kpositive = "de9d00";
      kpositiveSelection = "df9d00";

      text = "ece0d9";
      subtext1 = "d6c3b5";
      subtext0 = "9f8e81";
      overlay2 = "8b7b70";
      overlay1 = "76685e";
      overlay0 = "63574e";
      surface2 = "51463f";
      surface1 = "3f362f";
      surface0 = "2b241f";
      base = "18120e";
      mantle = "18120e";
      crust = "17110d";

      success = "B5CCBA";
      onSuccess = "213528";
      successContainer = "374B3E";
      onSuccessContainer = "D1E9D6";
    };
  };

  schemeJson = builtins.toJSON warmScheme;

  shellSettings = {
    appearance = {
      transparency.enabled = false;
      # Global scale knobs — applied to every shell surface (bar, dashboard,
      # popouts, launcher, etc.). Default 1.0 felt oversized at this display
      # density. 0.85 shrinks fonts, padding, and inter-element spacing
      # proportionally so the layout stays balanced.
      font.size.scale = 0.85;
      padding.scale = 0.85;
      spacing.scale = 0.85;
      # Scales every internal rounding token (popouts, bar segments, buttons).
      # Default 1 was overly bubbly given the small Hyprland window rounding.
      rounding.scale = 0.6;
    };
    # Outer screen-edge frame radius. Default 25 was the most visible curve.
    border.rounding = 12;
    general.apps = {
      terminal = [ "alacritty" ];
      audio = [ "pavucontrol" ];
      explorer = [ "nemo" ];
    };
    services.useTwelveHourClock = false;
    bar.status = {
      showBattery = true;
      showBluetooth = true;
      showNetwork = true;
      showWifi = true;
    };
    notifs = {
      # Auto-dismiss after 5s — swaync's default behaviour.
      expire = true;
      defaultExpireTimeout = 5000;
      # Don't trigger the notification's primary action on click; require an
      # explicit action button. Avoids accidental launches when clearing.
      actionOnClick = false;
      # How far you have to drag a card sideways before it dismisses.
      clearThreshold = 0.3;
    };
  };
  shellSettingsJson = builtins.toJSON shellSettings;

  cliSettings = {
    theme.enableGtk = false;
  };
  cliSettingsJson = builtins.toJSON cliSettings;

  # Per-component fixed pixel sizes live in shell-tokens.json, not shell.json.
  # These are not scaled by `appearance.*.scale` (which only touches font /
  # padding / spacing / rounding tokens), so dashboard pane widths and
  # launcher row sizes need to be reduced separately. Upstream README flags
  # these as internal and version-fragile — recheck after caelestia updates.
  shellTokens = {
    sizes = {
      dashboard = {
        # Dash tab
        infoWidth = 100;
        infoIconSize = 18;
        dateTimeWidth = 60;
        resourceSize = 110;
        # Media tab — these three drive most of the horizontal footprint:
        # implicitWidth = cover + visualiser*2 + details + bongocat + padding.
        mediaCoverArtSize = 80;
        mediaVisualiserSize = 40;
        mediaWidth = 100;
        mediaProgressSweep = 110;
        mediaProgressThickness = 5;
        resourceProgressThickness = 6;
        # Weather tab and the SmallWeather card on the Dash tab — bumped
        # back up from 140 since 140 squeezed the icon+temp+description trio
        # in the Dash tab card.
        weatherWidth = 180;
      };
      launcher = {
        itemWidth = 460;
        itemHeight = 46;
        wallpaperWidth = 220;
        wallpaperHeight = 160;
      };
    };
  };
  shellTokensJson = builtins.toJSON shellTokens;

  # Real (not symlinked) files: the shell needs to write to them at runtime
  # to avoid the "failed to write config" toast, but we still want this Nix
  # config to be authoritative. Activation writes the file unconditionally
  # on every rebuild; the shell picks up changes via its config watcher.
  # Side effect: any in-shell UI toggles (Control Center, launcher Dark/Light,
  # `caelestia scheme set`) are reverted on the next `nixos-rebuild switch`.
  writeFile = relPath: content: ''
    file="$HOME/${relPath}"
    mkdir -p "$(dirname "$file")"
    ${pkgs.coreutils}/bin/cat > "$file" <<'EOF'
${content}
EOF
  '';
in
{
  # Settings are NOT passed via `programs.caelestia.{settings,cli.settings}`
  # because that would make ~/.config/caelestia/{shell,cli}.json read-only
  # nix store symlinks. The shell writes back to those files when the user
  # changes settings via the Control Center / launcher, and that write fails
  # against a symlink (notified as "failed to write config to ..."). Seed
  # them as real files via activation instead.
  programs.caelestia = {
    enable = true;
    package = caelestiaShell;
    cli.enable = true;

    systemd = {
      enable = true;
      target = "graphical-session.target";
    };
  };

  home.activation.caelestiaSeed = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${writeFile ".local/state/caelestia/scheme.json" schemeJson}
    ${writeFile ".config/caelestia/shell.json" shellSettingsJson}
    ${writeFile ".config/caelestia/shell-tokens.json" shellTokensJson}
    ${writeFile ".config/caelestia/cli.json" cliSettingsJson}
  '';

  # Suppress blueman's tray applet — caelestia's status icons + popout already
  # handle bluetooth. The blueman daemon stays enabled at the NixOS layer for
  # adapter/pairing management. Shadowing the system .desktop in
  # ~/.config/autostart/ with Hidden=true is the standard XDG suppression.
  xdg.configFile."autostart/blueman.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Blueman Applet
    Hidden=true
  '';
}
