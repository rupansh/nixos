{
  services.vicinae = {
    enable = true;
    systemd = {
      enable = true;
      environment = {
        USE_LAYER_SHELL = 1;
      };
    };
    settings = {
      providers.applications.preferences.launchPrefix = "app2unit --";
    };
  };
}
