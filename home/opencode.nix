{ pkgs, opencode, ... }:
let
  ocPkgs = opencode.packages.${pkgs.stdenv.hostPlatform.system};

  # Upstream pins an `outputHash` for the dependency tree FOD
  # (`nix/node_modules.nix`, a `bun install --frozen-lockfile`) that no longer
  # matches what that build actually produces, so every rebuild dies with:
  #   specified: sha256-FY/I7zxmWA4tMvFZG5WijdqBcDc0No3a/YmKuxlluNg=
  #        got: sha256-Ppc2Kgb9D9xdkrNMyQgPS6rn/zU5zMqMKvAmrFCj1zQ=
  # The `got` value is stable across rebuilds, and it is NOT caused by our
  # `inputs.nixpkgs.follows` — opencode's own pinned nixpkgs resolves to the
  # same bun (1.4.2), and building with it reproduces the identical hash. So
  # upstream's recorded hash is simply stale; pin what the build really yields.
  #
  # `bun.lock` is frozen, so package versions are still pinned and bun keeps
  # verifying each package's own integrity hash — this override only restores
  # the Nix-level reproducibility check, it doesn't loosen dependency pinning.
  #
  # Revisit when bumping the opencode input: if upstream refreshes their hash,
  # drop this and go back to a plain `ocPkgs.opencode`. To recompute, build
  # `opencode.packages.<system>.node_modules_updater` — it deliberately uses
  # `lib.fakeHash` so the build failure reports the correct value.
  #node_modules = ocPkgs.node_modules_updater.override {
  #  hash = "sha256-Ppc2Kgb9D9xdkrNMyQgPS6rn/zU5zMqMKvAmrFCj1zQ=";
  #};
in
{
  programs.opencode = {
    enable = true;
    # latest from github:anomalyco/opencode instead of nixpkgs
    #package = ocPkgs.opencode.override { inherit node_modules; };
    enableMcpIntegration = true;

    extraPackages = with pkgs; [
      uv
      nodejs
    ];

    skills = import ./skills;
  };
}
