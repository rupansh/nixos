{
  description = "Rupansh's Nix Config";

  nixConfig = {
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://devenv.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix4vscode = {
      url = "github:nix-community/nix4vscode";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";
    mcp-servers-nix.url = "github:natsukium/mcp-servers-nix";
    caelestia-shell = {
      url = "github:caelestia-dots/shell";
      inputs.nixpkgs.follows = "nixpkgs";
      # upstream git.outfoxxed.me has an expired TLS certificate
      inputs.quickshell.url = "github:quickshell-mirror/quickshell";
      inputs.quickshell.inputs.nixpkgs.follows = "nixpkgs";
    };
    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    opencode = {
      url = "github:anomalyco/opencode";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Deliberately does NOT follow nixpkgs: the point is the prebuilt binary
    # from devenv.cachix.org (see the devenv overlay below).
    devenv.url = "github:cachix/devenv/v2.3.1";
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      nix4vscode,
      nix-index-database,
      mcp-servers-nix,
      caelestia-shell,
      spicetify-nix,
      opencode,
      devenv,
      ...
    }:
    let
      system = "x86_64-linux";
    in
    {
      nixosConfigurations."nix-rupansh" = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          (
            { config, pkgs, ... }:
            {
              nixpkgs.overlays = [
                nix4vscode.overlays.default
                (_: prev: {
                  openldap = prev.openldap.overrideAttrs {
                    doCheck = !prev.stdenv.hostPlatform.isi686;
                  };
                })
                # nixpkgs builds devenv 2.3.1 against a libghostty-vt older than
                # its bindings expect, so every interactive `devenv shell` dies
                # with "terminal error: invalid value" right after the tasks run
                # (cachix/devenv#3183). Use upstream's cached build until
                # nixos-unstable carries NixOS/nixpkgs#563205
                # (libghostty-vt >= 0.1.0-unstable-2026-08-06); then drop this
                # overlay, the `devenv` input and its cachix entries.
                (_: _: {
                  devenv = devenv.packages.${system}.default;
                })
              ];
            }
          )
          ./nixos/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit caelestia-shell opencode; };
            home-manager.users.rupansh = {
              imports = [
                nix-index-database.homeModules.nix-index
                mcp-servers-nix.homeManagerModules.default
                caelestia-shell.homeManagerModules.default
                spicetify-nix.homeManagerModules.spicetify
                ./home/bundle.nix
              ];
            };
          }
        ];
      };
    };
}
