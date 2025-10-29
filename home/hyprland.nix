{ pkgs, lib, config, ... }:
{
  xdg.configFile."uwsm/env".source =
    "${config.home.sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh";

  services.hyprpaper = {
    enable = true;
    settings = {
      ipc = true;
      splash = false;
      preload = [ "$HOME/Pictures/wallpaper.png" ];
      wallpaper = [ ",$HOME/Pictures/wallpaper.png" ];
    };
  };

  wayland.windowManager.hyprland = {
    enable = true;
    package = null;
    portalPackage = null;
    systemd.enable = false;
  };

  wayland.windowManager.hyprland.settings = {
    "$mod" = "SUPER";
    "$terminal" = "alacritty";
    "$menu" = "walker";

    general = {
      gaps_in = 5;
      gaps_out = 10;
      border_size = 1;
      "col.active_border" = "rgba(ccb333ee) rgba(bfcc33ee) 45deg";
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

    dwindle = {
      pseudotile = true;
      preserve_split = true;
    };

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

    gestures = {
      workspace_swipe = false;
    };

    bind =
      [
        "$mod, Return, exec, app2unit -- $terminal"
        "$mod, Q, killactive,"
        "$mod, M, exit,"
        "$mod, Space, togglefloating"
        "$mod, D, exec, app2unit -- $menu"
        "$mod, P, pseudo,"
        "$mod, J, togglesplit,"
        "$mod, F, fullscreen,"
        "$mod, left, movefocus, l"
        "$mod, right, movefocus, r"
        "$mod, up, movefocus, u"
        "$mod, down, movefocus, d"
        "$mod, X, togglespecialworkspace, magic"
        "$mod SHIFT, X, movetoworkspace, special:magic"
        "$mod SHIFT, S, exec, app2unit -- hyprshot -m region --clipboard-only"
      ]
      ++ (
        # binds $mod + [shift +] {1..9} to [move to] workspace {1..9}
        builtins.concatLists (
          builtins.genList (
            i:
            let
              ws = i + 1;
            in
            [
              "$mod, code:1${toString i}, workspace, ${toString ws}"
              "$mod SHIFT, code:1${toString i}, movetoworkspace, ${toString ws}"
            ]
          ) 9
        )
      );

    bindm = [
      "$mod, mouse_down, workspace e+1"
      "$mod, mouse_up, workspace e-1"
      "$mod, mouse:272, movewindow"
      "$mod, mouse:273, resizewindow"
    ];

    bindel = [
      ",XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
      ",XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
      ",XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
      ",XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
      ",XF86MonBrightnessUp, exec, brightnessctl --device intel_backlight -e4 -n2 set 5%+"
      ",XF86MonBrightnessDown, exec, brightnessctl --device intel_backlight -e4 -n2 set 5%-"
    ];

    bindl = [
      ", XF86AudioNext, exec, playerctl next"
      ", XF86AudioPause, exec, playerctl play-pause"
      ", XF86AudioPlay, exec, playerctl play-pause"
      ", XF86AudioPrev, exec, playerctl previous"
    ];

    windowrule = [
      "suppressevent maximize, class:.*"
      "nofocus,class:^$,title:^$,xwayland:1,floating:1,fullscreen:0,pinned:0"
    ];

    xwayland.force_zero_scaling = true;

    exec-once = [
      "app2unit -- ${lib.getExe pkgs.waybar} &"
      "app2unit -- elephant"
      "app2unit -- walker --gapplication-service"
    ];
  };

  home.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    HYPRCURSOR_SIZE = "24";
    AQ_DRM_DEVICES = "/dev/dri/card1:/dev/dri/card0";
  };
}
