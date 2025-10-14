{
  # for protonvpn
  networking.firewall.checkReversePath = "loose";
  networking.firewall.allowedTCPPorts = [
    # ssh
    22
    # spotify
    57621
  ];
  networking.firewall.allowedUDPPorts = [
    # spotify
    5353
  ];
}
