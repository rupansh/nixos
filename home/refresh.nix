{ pkgs, lib, ... }:
let
  # Match the internal eDP panel regardless of which connector index Hyprland
  # assigns (eDP-1, eDP-2, …). External displays are left untouched.
  primaryRegex = "^eDP-";

  refreshSwitch = pkgs.writeShellScript "hyprland-refresh-switch" ''
    set -u
    PATH=${
      lib.makeBinPath [
        pkgs.hyprland
        pkgs.jq
        pkgs.coreutils
        pkgs.systemd
      ]
    }

    apply() {
      local mon info res scale ac rate
      info=$(hyprctl monitors -j 2>/dev/null) || { echo "hyprctl unreachable"; return 0; }
      mon=$(echo "$info" | jq -r '.[] | select(.name | test("${primaryRegex}")) | .name' | head -1)
      if [ -z "$mon" ]; then echo "no ${primaryRegex} monitor"; return 0; fi
      ac=$(cat /sys/class/power_supply/AC*/online 2>/dev/null | head -1)
      if [ "$ac" = "1" ]; then rate=240; else rate=120; fi
      res=$(echo "$info"   | jq -r ".[] | select(.name == \"$mon\") | \"\(.width)x\(.height)\"")
      scale=$(echo "$info" | jq -r ".[] | select(.name == \"$mon\") | .scale")
      echo "applying: $mon,$res@$rate,auto,$scale (ac=$ac)"
      # configType = "lua" disables `hyprctl keyword`; the Lua-mode equivalent
      # is `eval` of an inline call against the in-memory hl.* API.
      hyprctl eval "hl.monitor({ output = '$mon', mode = '$res@$rate', position = 'auto', scale = $scale })"
    }

    apply
    # udevadm netlink monitor wakes only on real power_supply events, so this
    # loop blocks idle and doesn't burn cycles polling.
    exec udevadm monitor --kernel --subsystem-match=power_supply --property \
      | while IFS= read -r line; do
          case "$line" in
            POWER_SUPPLY_NAME=AC*) apply ;;
          esac
        done
  '';
in
{
  systemd.user.services.hyprland-refresh-switch = {
    Unit = {
      Description = "Drop Hyprland refresh rate to 60Hz on battery";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${refreshSwitch}";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
