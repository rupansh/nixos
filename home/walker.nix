{
  programs.walker = {
    enable = true;
    runAsService = false;
    config = {
      app_launch_prefix = "app2unit -- ";
    };
  };
}
