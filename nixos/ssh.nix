{ ... }: {
  services.openssh = {
    enable = true;
    ports = [ 22 ];
  };
  services.openssh.settings = {
    PasswordAuthentication = true;
    AllowUsers = null;
    UseDns = true;
    X11Forwarding = false;
    PermitRootLogin = "prohibit-password";
  };
}
