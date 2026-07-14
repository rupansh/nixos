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
- Pulls inputs `nixpkgs` (unstable), `home-manager`, `nix4vscode`, `nix-index-database`, `mcp-servers-nix`, `caelestia-shell` (desktop shell + launcher), `spicetify-nix`. All third-party inputs follow the same nixpkgs to keep one store closure.
- Applies overlays inline (currently `nix4vscode.overlays.default` and an `openldap.doCheck` workaround for i686).
- Imports `./nixos/configuration.nix` for system config.
- Imports home-manager as a NixOS module with `useGlobalPkgs` + `useUserPackages`, so home-manager shares the system's nixpkgs/overlays. The user's home config lives at `./home/bundle.nix`. `nix-index-database`, `mcp-servers-nix`, `caelestia-shell`, and `spicetify-nix` expose home-manager modules that are imported alongside it. `caelestia-shell` is also passed through via `home-manager.extraSpecialArgs` so `home/caelestia.nix` can override the shell package directly.

**`nixos/`** — system layer. `configuration.nix` is the aggregator; every other file is a focused module imported from it. Notable splits:
- `hardware-configuration.nix` is generator output — do not edit.
- `nvidia.nix` + `intel.nix` set up PRIME offload (Intel `PCI:0:2:0`, NVIDIA `PCI:1:0:0`) and kernel params to disable NVIDIA's backlight handler so Intel `intel_backlight` controls brightness.
- `asus.nix` runs `asusd` and enables `rog-control-center` with autostart.
- `modules.nix` enables top-level programs that need both system bits and user session integration: Hyprland with UWSM, Steam, virt-manager.
- `services.nix` force-disables a couple of unit `wantedBy` defaults (`nvidia-container-toolkit-cdi-generator`) — don't drop those `mkForce []` lines without understanding why.
- `configuration.nix` sets `environment.loginShellInit` to `uwsm start hyprland-uwsm.desktop`, so login on tty1 (autologin via `services.getty`) directly launches Hyprland under systemd user units.

**`home/`** — home-manager layer for user `rupansh`. `bundle.nix` is the aggregator and also sets `home.sessionVariables` (including `APP2UNIT_SLICES`/`APP2UNIT_TYPE`, used by Hyprland binds via `app2unit`).
- `hyprland.nix` — full Hyprland config in Nix (binds, animations off, dwindle layout, `rounding = 7`, `gaps_out = 15`). Apps are launched via `app2unit -- …` so they land in the right systemd slice. No wallpaper daemon — caelestia draws the wallpaper itself via `modules/background/Wallpaper.qml`. Uses Lua config (`configType = "lua"`, required because `home.stateVersion = 25.05` still defaults to the legacy hyprlang); home-manager renders attrs as `hl.<name>(...)` calls, so all variables live under one `config = {...}` attrset that becomes a single `hl.config({...})`. Binds use the `mkBind`/`mkBindOpts` helpers wrapping `{ _args = [...] }` with `lib.generators.mkLuaInline` for the dispatcher expression. The launcher and screenshot binds delegate to caelestia via `hl.dsp.exec_cmd("caelestia shell …")`; XF86 brightness keys use `hl.dsp.global("caelestia:brightnessUp"/"...Down")` so caelestia's in-memory `Monitor.brightness` observes the change and the OSD pops. Gradient colors (e.g. `col.active_border`) must be `{ colors = [...]; angle = N; }` tables — the old `"rgba(...) rgba(...) Ndeg"` string form is hyprlang-only and silently rejected by Lua. `nixos-rebuild switch` alone is enough to apply config changes; Hyprland watches its config file and auto-reloads. The only case that requires a full Hyprland restart is swapping between `hyprland.lua` and `hyprland.conf` — Hyprland caches the config-path choice (lua first, conf as fallback) in a C++ `static` at startup.
- `caelestia.nix` — desktop shell, app launcher, bar, notif daemon, OSD, wallpaper renderer, and screenshot picker (replaces waybar + vicinae + swaync + hyprpaper). The shell package is the `caelestia-shell.packages.<system>.with-cli` flake output, but wrapped via `overrideAttrs.postPatch` to substitute the hardcoded magic number in `modules/dashboard/WeatherTab.qml` (the weather tab is too wide upstream); the Performance tab is shrunk via `Tokens.sizes.dashboard.perf*` overrides in `shell-tokens.json` instead and to pin `services/Brightness.qml`'s `brightnessctl` to `--device intel_backlight -n2` (no `-e<n>` exponent — caelestia displays the linear raw_current/raw_max ratio, so an exponential setter would desync the slider from the actual brightness). `shell.json` / `cli.json` / `shell-tokens.json` / `~/.local/state/caelestia/scheme.json` are written by a `home.activation` script (always overwrite — Nix is source of truth, in-shell UI toggles get reverted on rebuild). `programs.caelestia.settings` is intentionally NOT used because that would make the JSON files read-only nix-store symlinks, and the shell tries to write to `shell.json` on startup — failed writes show a "failed to write config" toast. The seeded scheme is the shipped `gruvbox/soft/dark` (the only built-in with a warm orange primary) with the M3 `tertiary` group manually swapped to warm amber so the bar clock isn't yellow-green. A `xdg.configFile` override shadows `blueman.desktop` with `Hidden=true` to suppress the duplicate bluetooth tray icon (caelestia's status icons already handle BT).
- `spicetify.nix` — wraps Spotify with the `aurora` theme + extension bundle. Aurora ships prebuilt JS only in its GitHub release tarball, so we `fetchurl` the v0.1.8 tarball into a tiny `auroraRelease` derivation exposing `theme/` and `extensions/`. `replaceColors = false` is important — Aurora extracts accent colors from album art at runtime and would conflict with spicetify-nix's color.ini → CSS-variable rewrite. `pkgs.spotify` must NOT also be in `home.packages` (spicetify-nix installs its own wrapped binary).
- `obs.nix` — `programs.obs-studio` with `wlrobs`, `obs-pipewire-audio-capture`, `obs-backgroundremoval`. Virtual camera ("Start Virtual Camera" button) requires the `v4l2loopback` kernel module and is NOT enabled — re-add at the NixOS layer if needed.
- `vscode.nix` — VSCode extensions come from `pkgs.nix4vscode.forVscode` (overlay-provided). `nil` is the Nix LSP, with `nixfmt` as formatter.
- `claude-code.nix` — enables `programs.claude-code` (with MCP integration) and a Playwright MCP server, both via the `mcp-servers-nix` module.
- `git.nix` uses `includeIf gitdir:` to rewrite GitHub URLs to different SSH host aliases (`github-rupansh`, `github-rupansh-gob`) depending on which directory the repo lives in.

## Conventions

- Each concern lives in its own `.nix` file under `nixos/` or `home/`, then is imported by `configuration.nix` / `bundle.nix`. When adding a new program/service, create a new file rather than expanding an existing unrelated one.
- `programs.X.enable = true;` form is preferred over manually installing packages in `home.packages` / `environment.systemPackages` whenever a home-manager/NixOS module exists for it.
- Unfree is allowed system-wide (`nixpkgs.config.allowUnfree = true;` in `nixos/pkgs.nix`); since home-manager uses `useGlobalPkgs`, the user inherits this.
- `system.stateVersion` / `home.stateVersion` are pinned to `25.05` — do not bump these casually.
