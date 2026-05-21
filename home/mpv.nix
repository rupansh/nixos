{ pkgs, ... }:
{
  programs.mpv = {
    enable = true;

    # The home-manager mpv module makes `package` mutually exclusive with
    # `scripts`, so bake both ffmpeg-full (needed for full codec coverage
    # incl. DV metadata) and the scripts into a single wrapped package via
    # `pkgs.mpv.override`.
    package = pkgs.mpv.override {
      mpv-unwrapped = pkgs.mpv-unwrapped.override {
        ffmpeg = pkgs.ffmpeg-full;
      };
      scripts = with pkgs.mpvScripts; [
        uosc
        thumbfast
        mpris
      ];
    };

    config = {
      # uosc replaces the built-in OSC and window chrome.
      osc = false;
      osd-bar = false;
      border = false;

      # HDR10 / Dolby Vision pipeline. gpu-next is required for proper
      # HDR/DV handling; vulkan is the preferred backend on Wayland.
      vo = "gpu-next";
      gpu-api = "vulkan";
      # Advertise HDR colorspace to the compositor (Hyprland honours this
      # when its experimental HDR is enabled; ignored otherwise).
      target-colorspace-hint = true;
      # Dynamic peak detection for HDR10+/DV tone mapping.
      hdr-compute-peak = true;
      tone-mapping = "bt.2446a";

      hwdec = "auto-safe";

      keep-open = true;
      save-position-on-quit = true;

      slang = "eng,en";

      # Subtitles — mpv's default 55pt feels oversized; 36pt reads as
      # cinematic without straining at 1080p. `sub-ass-override=scale`
      # keeps signs/positioning from ASS subs but lets our size/border
      # tweaks still apply.
      sub-font = "Noto Sans";
      sub-font-size = 32;
      sub-bold = true;
      sub-border-size = 2.4;
      sub-border-color = "0.0/0.0/0.0/0.85";
      sub-shadow-offset = 1;
      sub-shadow-color = "0.0/0.0/0.0/0.5";
      sub-margin-y = 48;
      sub-ass-override = "scale";

      screenshot-format = "png";
      screenshot-directory = "~/Pictures/mpv-screenshots";
    };

    scriptOpts = {
      uosc = {
        # Timeline
        timeline_style = "line";
        timeline_line_width = 3;
        timeline_size = 44;
        timeline_cache = true;

        # Top bar (window chrome — recall border=no in mpv config)
        top_bar = "no-border";
        top_bar_size = 40;
        top_bar_controls = "right";
        top_bar_title = "yes";
        top_bar_alt_title_place = "below";

        # Controls row (the icons above the timeline)
        controls_size = 32;
        controls_margin = 8;

        # Typography / shape
        font_bold = true;
        text_border = 1.5;
        border_radius = 8;

        # Theme — match the gold accent from the Hyprland active border.
        color = "foreground=ccb333,foreground_text=1a1a1a,background=1a1a1a,background_text=ffffff";
        opacity = "timeline=0.85,controls=0.85,top_bar=0.85,tooltip=0.9,menu=0.95";
        animation_duration = 120;

        # UX
        proximity_in = 30;
        proximity_out = 140;
        autoload = true;
        pause_indicator = "static";
        idle_indicator = "logo";

        # Heatmap-style coloring for chapter ranges (anime OP/ED, sponsor segments).
        chapter_ranges = "openings:30abf964,endings:30abf964,intros:30abf964,outros:30abf964,ads:c54e4e80";
      };
    };
  };

  # Make mpv the default handler for video files so Nemo's double-click
  # / "Open" lands here without picking it from the "Open With" menu.
  xdg.mimeApps = {
    enable = true;
    defaultApplications =
      let
        mpv = [ "mpv.desktop" ];
      in
      {
        "video/mp4" = mpv;
        "video/x-matroska" = mpv;
        "video/webm" = mpv;
        "video/quicktime" = mpv;
        "video/x-msvideo" = mpv;
        "video/x-flv" = mpv;
        "video/mpeg" = mpv;
        "video/3gpp" = mpv;
        "video/x-ms-wmv" = mpv;
        "application/vnd.apple.mpegurl" = mpv;
        "application/x-mpegurl" = mpv;
      };
  };
}
