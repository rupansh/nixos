---
name: nixos-config
description: Safely inspect, modify, and rebuild the nix-rupansh NixOS + home-manager flake
---

## What this is

A single-flake NixOS config for host `nix-rupansh` (x86_64-linux, Intel+NVIDIA PRIME
laptop), with home-manager wired in as a NixOS module for user `rupansh`. Everything
lives in one git repo; there is no separate system/home split at the repo level.

- `flake.nix` — the only entrypoint. Defines `nixosConfigurations."nix-rupansh"`,
  pulls in all third-party inputs (all following the same `nixpkgs` to keep one store
  closure), applies overlays, and imports `nixos/configuration.nix` (system) plus
  `home/bundle.nix` via `home-manager.users.rupansh` (user).
- `nixos/` — system layer. `configuration.nix` is the aggregator; every other file is
  a focused module imported from it (hardware, nvidia/intel PRIME, asus tooling,
  hyprland/steam/virt-manager enablement, service overrides).
- `home/` — home-manager layer. `bundle.nix` is the aggregator; every other file is
  one program/concern.

## Commands

Apply a system + home-manager change:
```
sudo nixos-rebuild switch --flake .#nix-rupansh
```

Test without making it the boot default (reverts on reboot):
```
sudo nixos-rebuild test --flake .#nix-rupansh
```

Update flake inputs, then rebuild:
```
nix flake update
sudo nixos-rebuild switch --flake .#nix-rupansh
```

Format a Nix file (matches what the editor/LSP uses):
```
nixfmt <file>.nix
```

Check the flake still evaluates after an edit, before rebuilding:
```
nix flake check
```

## Conventions to follow when editing this repo

- One concern per file under `nixos/` or `home/`, imported by `configuration.nix` /
  `bundle.nix`. Adding a new program/service means creating a new file, not
  expanding an unrelated existing one.
- Prefer `programs.<name>.enable = true;` over manually listing packages in
  `home.packages` / `environment.systemPackages` whenever a home-manager/NixOS
  module exists for the program.
- `system.stateVersion` / `home.stateVersion` are pinned to `25.05` — never bump
  these without being asked.
- `hardware-configuration.nix` is generator output — never hand-edit it.
- Hyprland config changes apply automatically on `nixos-rebuild switch` (Hyprland
  watches its config file); no `hyprctl reload` or restart needed. The only
  exception is switching between `hyprland.lua` and `hyprland.conf`, which needs a
  full Hyprland restart because the config-path choice is cached in a C++ static at
  startup.
- This repo's Hyprland config is Lua-mode (`configType = "lua"`), so `hyprctl
  keyword ...` does not work here — use `hyprctl eval "hl.<api>({ ...named
  fields... })"` instead when driving Hyprland from the command line.

## Before proposing a change

1. Read the target file and its neighbors in the same directory first — conventions
   are enforced by example, not by a style guide.
2. Run `nix flake check` after any edit, before telling the user it's ready to
   rebuild.
3. Never run `sudo nixos-rebuild switch` unprompted — it's a system-wide, real
   effect change. Prefer `nixos-rebuild test` or just `nix flake check` /
   `nix build .#nixosConfigurations.nix-rupansh.config.system.build.toplevel`
   to validate, and let the user decide when to actually switch.
