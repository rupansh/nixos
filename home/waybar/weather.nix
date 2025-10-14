{ pkgs, ... }:
let
  weatherScript = pkgs.writeShellApplication {
    name = "waybar-weather-sh";
    runtimeInputs = with pkgs; [ curl jq ];
    text = ''
      weather_url=$(curl -s "https://ipinfo.io" | jq -r '.loc | split(",") | "https://api.open-meteo.com/v1/forecast?latitude=\(.[0])&longitude=\(.[1])&current=temperature_2m,weather_code,is_day"')

      readarray -t temp_data < <(curl -s "$weather_url" | jq -r '.current | "\(.temperature_2m)\n\(.weather_code)\n\(.is_day)\n"')

      weather_code=''${temp_data[1]}
      is_day=''${temp_data[2]}

      # weather icons
      declare -A weather_icons

      # mapped as $(weather_code)_$(is_day)
      # ref https://github.com/open-meteo/open-meteo/issues/789
      weather_icons["0_1"]=
      weather_icons["0_0"]=
      weather_icons["1_1"]=
      weather_icons["1_0"]=
      weather_icons["2_1"]=
      weather_icons["2_0"]=
      weather_icons["3_1"]=
      weather_icons["3_0"]=
      weather_icons["45_1"]=
      weather_icons["45_0"]=
      weather_icons["48_1"]=
      weather_icons["48_0"]=
      weather_icons["51_1"]=
      weather_icons["51_0"]=
      weather_icons["53_1"]=
      weather_icons["53_0"]=
      weather_icons["55_1"]=
      weather_icons["55_0"]=
      weather_icons["80_1"]=
      weather_icons["80_0"]=
      weather_icons["81_1"]=
      weather_icons["81_0"]=
      weather_icons["82_1"]=
      weather_icons["82_0"]=
      weather_icons["61_1"]=
      weather_icons["61_0"]=
      weather_icons["63_1"]=
      weather_icons["63_0"]=
      weather_icons["65_1"]=
      weather_icons["65_0"]=
      weather_icons["56_1"]=
      weather_icons["56_0"]=
      weather_icons["57_1"]=
      weather_icons["57_0"]=
      weather_icons["66_1"]=
      weather_icons["66_0"]=
      weather_icons["67_1"]=
      weather_icons["67_0"]=
      weather_icons["77_1"]=
      weather_icons["77_0"]=
      weather_icons["71_1"]=
      weather_icons["71_0"]=
      weather_icons["73_1"]=
      weather_icons["73_0"]=
      weather_icons["75_1"]=
      weather_icons["75_0"]=
      weather_icons["95_0"]=
      weather_icons["95_1"]=
      weather_icons["96_1"]=
      weather_icons["96_0"]=
      weather_icons["97_1"]=
      weather_icons["97_0"]=

      weather_icon=''${weather_icons["''${weather_code}_''${is_day}"]}
      echo -e "''${weather_icon}  ''${temp_data[0]}°\nWeather\nweatherClass\n"
    '';
  };
in { programs.waybar.settings.mainBar."custom/weather".exec = "${weatherScript}/bin/${weatherScript.name}"; }
