{
  description = "Rupansh's Nix Config";

  nixConfig = {
    extra-substituters = [
      "https://vicinae.cachix.org"
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    vicinae.url = "github:vicinaehq/vicinae";
    nix4vscode = {
      url = "github:nix-community/nix4vscode";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";
    mcp-servers-nix.url = "github:natsukium/mcp-servers-nix";
  };

  outputs =
    {
      nixpkgs,
      home-manager,
      vicinae,
      nix4vscode,
      nix-index-database,
      mcp-servers-nix,
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
              ];
            }
          )
          vicinae.nixosModules.default
          ./nixos/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.rupansh = {
              imports = [
                nix-index-database.homeModules.nix-index
                mcp-servers-nix.homeManagerModules.default
                vicinae.homeManagerModules.default
                ./home/bundle.nix
              ];
            };
          }
        ];
      };
    };
}
