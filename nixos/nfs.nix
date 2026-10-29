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
# Stopping it must never wait on the desktop. `-l -f` alone doesn't get
# there: the lazy detach returns, but the kernel's final writeback and
# NFSv4 session teardown still block on a hard mount whose server has gone
# away. `sd-pc-teardown.service` (bound to the mount, stopped right before
# it) closes that gap with the NFS client's sysfs `shutdown` knob, which
# makes every outstanding and future RPC on the mount fail immediately.
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

      # TCP probe of the NFS port, so mounting takes the fast path when the
      # desktop is off / off the tailnet instead of mount.nfs retrying.
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
        # Flushing, and cutting the share loose when the desktop is gone,
        # happen in sd-pc-teardown.service's ExecStop, which every stop of
        # the mount (this, a plain systemctl stop, shutdown) goes through.
        if systemctl stop "$mp"; then
          report "unmounted $mp"
        else
          report "unmount failed — see: systemctl status $mp"
          return 1
        fi
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

  # ExecStop of sd-pc-teardown.service; runs while the share is still
  # mounted and (see the mount's `after`) while tailscaled is still up.
  # Leaves the mount in a state where the umount that follows returns
  # immediately, whether or not the desktop is still there.
  sd-pc-teardown = pkgs.writeShellApplication {
    name = "sd-pc-teardown";
    runtimeInputs = [
      config.systemd.package
      config.services.tailscale.package
      pkgs.coreutils
      pkgs.gnugrep
      pkgs.util-linux
      pkgs.jq
    ];
    text = ''
      mp=${mountPoint}

      # All of this reads /proc/self/mountinfo only: anything that stat()s
      # the mount point could itself hang on a dead server.
      if ! mnt=$(findmnt -nro MAJ:MIN,OPTIONS --mountpoint "$mp"); then
        exit 0
      fi
      read -r dev opts <<<"$mnt"
      # Empty if absent, which peer_online then treats as unreachable.
      addr=$(grep -oP '(^|,)addr=\K[^,]+' <<<"$opts" || true)
      knob=/sys/fs/nfs/$dev/shutdown

      # Local query to tailscaled; no network round trip. Fails fast when
      # tailscaled is stopped, which means there is no path to the server.
      peer_online() {
        timeout 1 tailscale status --json 2>/dev/null |
          jq -e --arg ip "$addr" \
            'any(.Peer[]?; (.TailscaleIPs | index($ip)) and .Online)' \
            >/dev/null
      }

      # A real round trip, for when there's time to be sure.
      server_reachable() {
        timeout 2 "$BASH" -c "exec 3<>/dev/tcp/$addr/2049" 2>/dev/null
      }

      cut_loose() {
        echo "$1 — shutting down the NFS client; unflushed writes are dropped"
        echo 1 >"$knob"
      }

      if [ "$(systemctl is-system-running)" = stopping ]; then
        # Shutdown. Everything that could have had the share open has
        # exited by now, and NFS flushes dirty data on close(), so there is
        # almost never anything left to write: a global sync (which, unlike
        # `sync -f`, doesn't open the mount point) then returns at once. It
        # is only worth even that when the desktop can possibly receive it,
        # and it is capped so a stale "online" can't stall poweroff.
        if peer_online; then
          timeout -s KILL 3 sync || echo "flush to $addr stalled"
        fi
        # Always, even when the flush succeeded: the unmount's NFSv4 session
        # teardown is more RPCs to a server that may be halfway gone, and
        # skipping it just leaves the desktop to expire our lease.
        echo 1 >"$knob"
        exit 0
      fi

      # Manual stop: the user may still be writing to the share (the unmount
      # is lazy), so only cut it loose when the desktop really can't answer.
      if ! peer_online || ! server_reachable; then
        cut_loose "$addr is unreachable"
      elif ! timeout -s KILL 60 sync -f "$mp"; then
        cut_loose "flush to $addr stalled"
      fi
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
      # The server is only reachable over the tailnet, but the default network
      # mount deps only order us after network(-online).target, which
      # tailscaled isn't part of. Without this, shutdown stops tailscaled in
      # parallel with the unmount and the route to the server vanishes first.
      # Stop order is start order reversed, so this (and the teardown service,
      # which is ordered after us) runs while the tailnet is still up.
      after = [ "tailscaled.service" ];
      mountConfig = {
        # Stop = `umount -l -f`: detach the mount point even if something
        # still has files open on it, and abort RPCs in flight. After the
        # teardown service has set the shutdown knob this is instant.
        LazyUnmount = true;
        ForceUnmount = true;
        # Backstop only; nothing above should ever get near it.
        TimeoutSec = "30s";
      };
    }
  ];

  systemd.services.sd-pc-teardown = {
    description = "Flush or cut loose the sd-pc NFS share before unmounting";
    # Started with the mount, stopped with it (BindsTo) and, being ordered
    # after it, stopped *before* the unmount runs.
    wantedBy = [ unit ];
    bindsTo = [ unit ];
    after = [ unit ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStop = "${sd-pc-teardown}/bin/sd-pc-teardown";
      # Its own caps are 1+3s at shutdown and 1+2+60s otherwise.
      TimeoutStopSec = "90s";
    };
  };

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
