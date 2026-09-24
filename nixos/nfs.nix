# `~/sd-pc`: NFS share of the desktop's SD card folder, mounted on demand.
#
# The share is a plain `systemd.mounts` unit (not a `fileSystems` entry) so
# we can set the `[Mount]` unmount knobs below; no `wantedBy` means the
# `home-rupansh-sd\x2dpc.mount` unit exists but nothing pulls it in at boot.
# systemd's default dependencies still tie it to `umount.target`, so it is
# unmounted on shutdown like any other mount. Toggling is just starting /
# stopping that unit; the polkit rule below lets rupansh do so without a
# password, which is what makes it work from a plain user shell, a keybind
# or a launcher.
#
# The mount point itself is created (root-owned, 0755) by systemd the first
# time the unit starts. That is intentional: while the share is unmounted
# nothing can accidentally be written into the placeholder directory.
{
  config,
  pkgs,
  utils,
  ...
}:
let
  mountPoint = "/home/rupansh/sd-pc";
  share = "omarchy-rs:/media/rupansh/wdblack/sd";
  host = builtins.head (builtins.split ":" share);
  unit = "${utils.escapeSystemdPath mountPoint}.mount";

  # `sd-pc [toggle|mount|umount|status]` — `toggle` is the default.
  # Reports on stdout when run from a terminal, otherwise (keybind, launcher)
  # via a desktop notification so the result is still visible.
  sd-pc = pkgs.writeShellApplication {
    name = "sd-pc";
    runtimeInputs = [
      config.systemd.package
      pkgs.coreutils
      pkgs.util-linux
      pkgs.libnotify
    ];
    text = ''
      mp=${mountPoint}
      share=${share}
      host=${host}

      usage() {
        echo "usage: sd-pc [toggle|mount|umount|status]" >&2
        exit 64
      }

      is_mounted() {
        findmnt --mountpoint "$mp" >/dev/null
      }

      # TCP probe of the NFS port. A hard NFS mount retries forever against a
      # server that has gone away, so both directions check first and take
      # the fast path when the desktop is off / off the tailnet.
      server_reachable() {
        timeout 3 "$BASH" -c "exec 3<>/dev/tcp/$host/2049" 2>/dev/null
      }

      report() {
        if [ -t 1 ]; then
          echo "$1"
        else
          notify-send --app-name=sd-pc --icon=drive-harddisk "sd-pc" "$1"
        fi
      }

      do_mount() {
        if is_mounted; then
          report "already mounted at $mp"
          return 0
        fi
        if ! server_reachable; then
          report "$host is unreachable — not mounting"
          return 1
        fi
        # systemctl maps an absolute path to the matching .mount unit.
        if systemctl start "$mp"; then
          report "mounted $share at $mp"
        else
          report "mount failed — see: systemctl status $mp"
          return 1
        fi
      }

      do_umount() {
        if ! is_mounted; then
          report "not mounted"
          return 0
        fi
        if server_reachable; then
          # Flush while the server is up: the unit unmounts with `-f`, which
          # aborts in-flight RPCs, and we don't want that to eat writes that
          # were merely still sitting in the page cache.
          sync -f "$mp"
          if systemctl stop "$mp"; then
            report "unmounted $mp"
            return 0
          fi
          report "unmount failed — see: systemctl status $mp"
          return 1
        fi
        # Server gone. The lazy+forced unmount detaches the tree right away;
        # whatever is left of the teardown can only finish (or hit the unit's
        # TimeoutSec) in the background, so don't wait on the job — just on
        # the mount point disappearing.
        systemctl stop --no-block "$mp"
        for _ in $(seq 20); do
          is_mounted || break
          sleep 0.25
        done
        if is_mounted; then
          report "unmount failed — see: systemctl status $mp"
          return 1
        fi
        report "detached $mp — $host is unreachable, pending writes could not be flushed"
      }

      case "''${1:-toggle}" in
        toggle)
          if is_mounted; then do_umount; else do_mount; fi
          ;;
        mount) do_mount ;;
        umount) do_umount ;;
        status)
          if is_mounted; then
            findmnt --mountpoint "$mp" -o SOURCE,TARGET,FSTYPE,OPTIONS
          else
            echo "$mp: not mounted"
            exit 1
          fi
          ;;
        *) usage ;;
      esac
    '';
  };
in
{
  # Normally derived from `fileSystems.*.fsType`; this is what makes the
  # NixOS NFS module wire up rpcbind / nfs-utils / nfs-client.target.
  boot.supportedFilesystems.nfs = true;

  systemd.mounts = [
    {
      description = "sd-pc NFS share";
      what = share;
      where = mountPoint;
      type = "nfs";
      options = "nfsvers=4.2";
      mountConfig = {
        # Stop = `umount -l -f`. A hard NFS mount whose server has vanished
        # otherwise blocks in umount(2) until TimeoutSec, on shutdown too.
        # Lazy detaches the mount point immediately; force aborts the RPCs
        # any process stuck on it is waiting for (they get EIO instead of
        # sitting in D state until the server returns). `sd-pc umount`
        # syncfs()es first when the server is reachable so the force never
        # discards pending writes on a healthy share.
        LazyUnmount = true;
        ForceUnmount = true;
        # Caps both mount.nfs against a server that stopped answering
        # mid-probe and a teardown that got stuck anyway. Default is 90s.
        TimeoutSec = "30s";
      };
    }
  ];

  security.polkit.extraConfig = ''
    polkit.addRule(function (action, subject) {
      if (action.id == "org.freedesktop.systemd1.manage-units"
          && action.lookup("unit") == ${builtins.toJSON unit}
          && subject.user == "rupansh") {
        return polkit.Result.YES;
      }
    });
  '';

  environment.systemPackages = [ sd-pc ];
}
