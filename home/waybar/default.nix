{ ... }:
{
  imports = [
    ./weather.nix
    ./style.nix
  ];

  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        spacing = 0;
        height = 35;
        margin = "0 0 0 0";
        modules-left = [
          "group/utility"
          "custom/playerctl#backward"
          "custom/playerctl#play"
          "custom/playerctl#forward"
          "custom/playerlabel"
        ];
        modules-center = [
          "custom/weather"
          "hyprland/workspaces"
          "custom/swaync"
        ];
        modules-right = [
          "tray"
          "battery"
          "pulseaudio"
          "network"
          "clock"
        ];

        "hyprland/workspaces" = {
          format = "{name}";
          on-click = "activate";
          on-scroll-down = "hyprctl dispatch workspace e+1";
          on-scroll-up = "hyprctl dispatch worspace e-1";
        };

        "custom/weather" = {
          format = "{}";
          interval = 3600;
        };

        "custom/swaync" = {
          tooltip = true;
          tooltip-format = "Left Click: Launch Notification Center\nRight Click: Do not Disturb";
          format = "{} {icon} ";
          format-icons = {
            notification = "<span foreground='#e67e80'><sup></sup></span>";
            none = "";
            dnd-notification = "<span foreground='#e67e80'><sup></sup></span>";
            dnd-none = "";
            inhibited-notification = "<span foreground='#e67e80'><sup></sup></span>";
            inhibited-none = "";
            dnd-inhibited-notification = "<span foreground='#e67e80'><sup></sup></span>";
            dnd-inhibited-none = "";
          };
          return-type = "json";
          exec = "swaync-client -swb";
          on-click = "sleep 0.1 && swaync-client -t -sw";
          on-click-right = "swaync-client -d -sw";
          escape = true;
        };

        cpu = {
          format = "󰻠";
          tooltip = true;
        };

        memory = {
          format = "";
        };

        temperature = {
          # zeph g16 runs hot lol
          critical-threshold = 95;
          format = "";
        };

        idle_inhibitor = {
          format = "{icon}";
          format-icons = {
            activated = "";
            deactivated = "";
          };
        };

        "custom/expand" = {
          format = "";
          tooltip = true;
          tooltip-format = "Click to show utilities";
        };

        "group/utility" = {
          orientation = "inherit";
          drawer = {
            transition-duration = 600;
            children-class = "child-utility";
            transition-left-to-right = true;
            click-to-reveal = true;
          };
          modules = [
            "custom/expand"
            "cpu"
            "memory"
            "temperature"
            "idle_inhibitor"
          ];
        };

        "custom/playerctl#backward" = {
          format = "󰙣 ";
          on-click = "playerctl previous";
          on-scroll-down = "wpctl set-volume @DEFAULT_SINK@ 5%-";
          on-scroll-up = "wpctl set-volume -l 1 @DEFAULT_SINK@ 5%+";
          tooltip = false;
        };
        "custom/playerctl#forward" = {
          format = "󰙡 ";
          on-click = "playerctl next";
          on-scroll-down = "wpctl set-volume @DEFAULT_SINK@ 5%-";
          on-scroll-up = "wpctl set-volume -l 1 @DEFAULT_SINK@ 5%+";
          tooltip = false;
        };
        "custom/playerctl#play" = {
          exec = "playerctl -a metadata --format '{\"text\": \"{{artist}} - {{markup_escape(title)}}\", \"tooltip\": \"{{playerName}} : {{markup_escape(title)}}\", \"alt\": \"{{status}}\", \"class\": \"{{status}}\"}' -F";
          format = "{icon}";
          format-icons = {
            Paused = "<span> </span>";
            Playing = "<span>󰏥 </span>";
            Stopped = "<span> </span>";
          };
          on-click = "playerctl play-pause";
          on-scroll-down = "wpctl set-volume @DEFAULT_SINK@ 5%-";
          on-scroll-up = "wpctl set-volume -l 1 @DEFAULT_SINK@ 5%+";
          return-type = "json";
        };
        "custom/playerlabel" = {
          exec = "playerctl -a metadata --format '{\"text\": \"{{artist}} - {{markup_escape(title)}}\", \"tooltip\": \"{{playerName}} : {{markup_escape(title)}}\", \"alt\": \"{{status}}\", \"class\": \"{{status}}\"}' -F";
          format = "<span>󰎈 {} 󰎈</span>";
          max-length = 40;
          on-click = "";
          return-type = "json";
        };
        # ---------------Battery-------------

        battery = {
          format = "{icon}  {capacity}%";
          format-alt = "{icon} {time}";
          format-charging = " {capacity}%";
          format-icons = [
            ""
            ""
            ""
            ""
            ""
          ];
          format-plugged = " {capacity}% ";
          format-time = "{H} h {m} min";
          states = {
            critical = 15;
            good = 80;
            warning = 3;
          };
        };

        # ---------------Pulseaudio------------
        pulseaudio = {
          format = "{icon} {volume}%";
          format-icons = {
            default = [
              "󰕿"
              "󰖀"
              "󰕾"
            ];
          };
          format-muted = "󰝟";
          on-click = "pavucontrol";
          scroll-step = 5;
        };

        # --------------Network-----------------
        network = {
          format-disconnected = "󰖪 0% ";
          format-ethernet = "󰈀 100% ";
          format-linked = "{ifname} (No IP)";
          format-wifi = "  {signalStrength}%";
          tooltip-format = "Connected to {essid} {ifname} via {gwaddr}";
          on-click = "alacritty --title=TermNmtui -e 'sleep 0.1; nmtui'";
        };

        # ------------Tray--------------------
        tray = {
          icon-size = 20;
          spacing = 8;
        };

        # ------------Clock------------------
        clock = {
          format = "󰥔 {:%I:%M:%S %p} ";
          interval = 1;
          tooltip-format = "<tt>{calendar}</tt>";
          calendar = {
            format = {
              today = "<span color='#d699b6'><b>{}</b></span>";
            };
          };
          actions = {
            on-click-right = "shift_down";
            on-click = "shift_up";
          };
        };
      };
    };
  };
}
