{ pkgs, lib, config, ... }:
let
  mod = "SUPER";
  terminal = "alacritty";

  lua = lib.generators.mkLuaInline;

  mkBind = key: dsp: { _args = [ key (lua dsp) ]; };
  mkBindOpts = key: dsp: opts: { _args = [ key (lua dsp) opts ]; };

  workspaceBinds = lib.concatLists (
    lib.genList (
      i:
      let
        ws = i + 1;
      in
      [
        (mkBind "${mod} + code:1${toString i}" ''hl.dsp.focus({ workspace = ${toString ws} })'')
        (mkBind "${mod} + SHIFT + code:1${toString i}"
          ''hl.dsp.window.move({ workspace = ${toString ws} })''
        )
      ]
    ) 9
  );
in
{
  xdg.configFile."uwsm/env".source =
    "${config.home.sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh";

  wayland.windowManager.hyprland = {
    enable = true;
    package = null;
    portalPackage = null;
    systemd.enable = false;
    configType = "lua";
  };

  wayland.windowManager.hyprland.settings = {
    config = {
      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 1;
        "col.active_border" = {
          colors = [ "rgba(ccb333ee)" "rgba(bfcc33ee)" ];
          angle = 45;
        };
        "col.inactive_border" = "rgba(595959aa)";
        resize_on_border = true;
        allow_tearing = false;
        layout = "dwindle";
      };

      decoration = {
        rounding = 5;
        rounding_power = 2;
        active_opacity = 1.0;
        inactive_opacity = 1.0;
        shadow = {
          enabled = false;
          range = 4;
          render_power = 3;
          color = "rgba(1a1a1aee)";
        };
        blur = {
          enabled = false;
          size = 3;
          passes = 1;
          vibrancy = 0.1696;
        };
      };

      animations.enabled = false;

      dwindle.preserve_split = true;

      misc = {
        force_default_wallpaper = -1;
        disable_splash_rendering = true;
        disable_hyprland_logo = true;
      };

      input = {
        kb_layout = "us";
        follow_mouse = 1;
        sensitivity = 0;
        touchpad.natural_scroll = false;
      };

      xwayland.force_zero_scaling = true;
    };

    bind =
      [
        (mkBind "${mod} + Return" ''hl.dsp.exec_cmd("app2unit -- ${terminal}")'')
        (mkBind "${mod} + Q"      ''hl.dsp.window.close()'')
        (mkBind "${mod} + M"      ''hl.dsp.exit()'')
        (mkBind "${mod} + Space"  ''hl.dsp.window.float({ action = "toggle" })'')
        (mkBind "${mod} + D"      ''hl.dsp.exec_cmd("caelestia shell drawers toggle launcher")'')
        (mkBind "${mod} + P"      ''hl.dsp.window.pseudo()'')
        (mkBind "${mod} + J"      ''hl.dsp.layout("togglesplit")'')
        (mkBind "${mod} + F"      ''hl.dsp.window.fullscreen()'')
        (mkBind "${mod} + left"   ''hl.dsp.focus({ direction = "l" })'')
        (mkBind "${mod} + right"  ''hl.dsp.focus({ direction = "r" })'')
        (mkBind "${mod} + up"     ''hl.dsp.focus({ direction = "u" })'')
        (mkBind "${mod} + down"   ''hl.dsp.focus({ direction = "d" })'')
        (mkBind "${mod} + X"          ''hl.dsp.workspace.toggle_special("magic")'')
        (mkBind "${mod} + SHIFT + X"  ''hl.dsp.window.move({ workspace = "special:magic" })'')
        # Caelestia's area picker freezes the screen on entry, so the snap
        # reflects what was on screen at keypress time rather than what's
        # there once you finish selecting. `openFreezeClip` = freeze + copy
        # to clipboard only (no file/swappy editor).
        (mkBind "${mod} + SHIFT + S"
          ''hl.dsp.exec_cmd("caelestia shell picker openFreezeClip")''
        )

        # Mouse scroll workspace switching
        (mkBind "${mod} + mouse_down" ''hl.dsp.focus({ workspace = "e+1" })'')
        (mkBind "${mod} + mouse_up"   ''hl.dsp.focus({ workspace = "e-1" })'')

        # Mouse drag/resize (was bindm)
        (mkBindOpts "${mod} + mouse:272" ''hl.dsp.window.drag()''   { mouse = true; })
        (mkBindOpts "${mod} + mouse:273" ''hl.dsp.window.resize()'' { mouse = true; })

        # Audio (was bindl — fire even while inhibited)
        (mkBindOpts "XF86AudioNext"  ''hl.dsp.exec_cmd("playerctl next")''       { locked = true; })
        (mkBindOpts "XF86AudioPause" ''hl.dsp.exec_cmd("playerctl play-pause")'' { locked = true; })
        (mkBindOpts "XF86AudioPlay"  ''hl.dsp.exec_cmd("playerctl play-pause")'' { locked = true; })
        (mkBindOpts "XF86AudioPrev"  ''hl.dsp.exec_cmd("playerctl previous")''   { locked = true; })

        # Volume + brightness (was bindel — repeat on hold, fire even while inhibited)
        (mkBindOpts "XF86AudioRaiseVolume"
          ''hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+")''
          { repeating = true; locked = true; }
        )
        (mkBindOpts "XF86AudioLowerVolume"
          ''hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-")''
          { repeating = true; locked = true; }
        )
        (mkBindOpts "XF86AudioMute"
          ''hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")''
          { repeating = true; locked = true; }
        )
        (mkBindOpts "XF86AudioMicMute"
          ''hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle")''
          { repeating = true; locked = true; }
        )
        (mkBindOpts "XF86MonBrightnessUp"
          ''hl.dsp.exec_cmd("brightnessctl --device intel_backlight -e4 -n2 set 5%+")''
          { repeating = true; locked = true; }
        )
        (mkBindOpts "XF86MonBrightnessDown"
          ''hl.dsp.exec_cmd("brightnessctl --device intel_backlight -e4 -n2 set 5%-")''
          { repeating = true; locked = true; }
        )
      ]
      ++ workspaceBinds;

    window_rule = [
      {
        match.class = ".*";
        suppress_event = "maximize";
      }
      {
        match = {
          class = "^$";
          title = "^$";
          xwayland = true;
          float = true;
          fullscreen = false;
          pin = false;
        };
        no_focus = true;
      }
    ];
  };

  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    HYPRCURSOR_SIZE = "24";
    AQ_DRM_DEVICES = "/dev/dri/card1";
  };
}
