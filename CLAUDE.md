# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Personal NixOS configuration for an Asus laptop with Intel + NVIDIA hybrid graphics (PRIME offload). Single host `nix-rupansh`, single user `rupansh`, `x86_64-linux`. Managed as a flake with home-manager wired in as a NixOS module.

## Commands

Apply a system + home-manager config change:
```
sudo nixos-rebuild switch --flake .#nix-rupansh
```

Test without making default (revert on reboot):
```
sudo nixos-rebuild test --flake .#nix-rupansh
```

Update inputs and rebuild:
```
nix flake update
sudo nixos-rebuild switch --flake .#nix-rupansh
```

Format Nix files (this is what the editor/LSP uses):
```
nixfmt <file>.nix
```

Check that the flake still evaluates after edits:
```
nix flake check
```

## Architecture

**`flake.nix`** is the single entrypoint. It defines one `nixosConfigurations."nix-rupansh"` that:
- Pulls inputs `nixpkgs` (unstable), `home-manager`, `walker` (launcher), `nix4vscode`, `nix-index-database`, `mcp-servers-nix`. All third-party inputs follow the same nixpkgs to keep one store closure.
- Applies overlays inline (currently `nix4vscode.overlays.default` and an `openldap.doCheck` workaround for i686).
- Imports `./nixos/configuration.nix` for system config.
- Imports home-manager as a NixOS module with `useGlobalPkgs` + `useUserPackages`, so home-manager shares the system's nixpkgs/overlays. The user's home config lives at `./home/bundle.nix`, and walker/nix-index/mcp-servers expose home-manager modules that are imported alongside it.

**`nixos/`** — system layer. `configuration.nix` is the aggregator; every other file is a focused module imported from it. Notable splits:
- `hardware-configuration.nix` is generator output — do not edit.
- `nvidia.nix` + `intel.nix` set up PRIME offload (Intel `PCI:0:2:0`, NVIDIA `PCI:1:0:0`) and kernel params to disable NVIDIA's backlight handler so Intel `intel_backlight` controls brightness.
- `asus.nix` runs `asusd` + `supergfxd`.
- `modules.nix` enables top-level programs that need both system bits and user session integration: Hyprland with UWSM, Steam, virt-manager.
- `services.nix` force-disables a couple of unit `wantedBy` defaults (`nvidia-container-toolkit-cdi-generator`, `home-manager-rupansh`) — don't drop those `mkForce []` lines without understanding why.
- `configuration.nix` sets `environment.loginShellInit` to `uwsm start hyprland-uwsm.desktop`, so login on tty1 (autologin via `services.getty`) directly launches Hyprland under systemd user units.

**`home/`** — home-manager layer for user `rupansh`. `bundle.nix` is the aggregator and also sets `home.sessionVariables` (including `APP2UNIT_SLICES`/`APP2UNIT_TYPE`, used by Hyprland binds via `app2unit`).
- `hyprland.nix` — full Hyprland config in Nix (binds, animations off, dwindle layout). Apps are launched via `app2unit -- …` so they land in the right systemd slice. Wallpaper at `$HOME/Pictures/wallpaper.png` via hyprpaper.
- `vscode.nix` — VSCode extensions come from `pkgs.nix4vscode.forVscode` (overlay-provided). `nil` is the Nix LSP, with `nixfmt` as formatter.
- `claude-code.nix` — enables `programs.claude-code` (with MCP integration) and a Playwright MCP server, both via the `mcp-servers-nix` module.
- `git.nix` uses `includeIf gitdir:` to rewrite GitHub URLs to different SSH host aliases (`github-rupansh`, `github-rupansh-gob`) depending on which directory the repo lives in.

## Conventions

- Each concern lives in its own `.nix` file under `nixos/` or `home/`, then is imported by `configuration.nix` / `bundle.nix`. When adding a new program/service, create a new file rather than expanding an existing unrelated one.
- `programs.X.enable = true;` form is preferred over manually installing packages in `home.packages` / `environment.systemPackages` whenever a home-manager/NixOS module exists for it.
- Unfree is allowed system-wide (`nixpkgs.config.allowUnfree = true;` in `nixos/pkgs.nix`); since home-manager uses `useGlobalPkgs`, the user inherits this.
- `system.stateVersion` / `home.stateVersion` are pinned to `25.05` — do not bump these casually.
