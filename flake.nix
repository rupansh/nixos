{
  description = "Rupansh's Nix Config";

  nixConfig = {
    extra-substituters = [
      "https://walker-git.cachix.org"
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "walker-git.cachix.org-1:vmC0ocfPWh0S/vRAQGtChuiZBTAe4wiKDeyyXM0/7pM="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    elephant.url = "github:abenz1267/elephant";
    walker = {
      url = "github:abenz1267/walker";
      inputs.nixpkgs.follows = "elephant";
    };
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
      walker,
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
          ./nixos/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.rupansh = {
              imports = [
                walker.homeManagerModules.default
                nix-index-database.homeModules.nix-index
                mcp-servers-nix.homeManagerModules.default
                ./home/bundle.nix
              ];
            };
          }
        ];
      };
    };
}
