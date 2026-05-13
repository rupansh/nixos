{ ... }: {
  virtualisation.libvirtd = {
    enable = true;
    qemu.swtpm.enable = true;
  };

  users.groups.libvirtd.members = [ "rupansh" ];
  users.groups.kvm.members = [ "rupansh" ];
}
