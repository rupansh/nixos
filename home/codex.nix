{
  config,
  lib,
  pkgs,
  ...
}:
let
  # The config.toml home-manager would have symlinked into place. We keep the
  # generated derivation but install it ourselves, see the activation script.
  managedConfig = config.home.file.".codex/config.toml".source;
in
{
  programs.codex = {
    enable = true;
    enableMcpIntegration = true;

    skills = import ./skills;
  };

  # config.toml must NOT be a read-only nix-store symlink. Codex persists
  # per-project trust as `[projects."<path>"]` inside config.toml the first
  # time it opens a directory, so with the default symlink every repo dies on
  # entry with `config/batchWrite failed: failed to persist config at
  # /nix/store/... (code -32603)` — codex is unusable anywhere. Same story for
  # `codex mcp add`, hook trust, and the TUI model picker.
  home.file.".codex/config.toml".enable = false;

  # Install it as a real file instead, merging rather than overwriting: Nix
  # fully owns every top-level key it sets (so dropping a server from mcp.nix
  # actually drops it here), while anything codex wrote for itself — project
  # trust, hook trust, model picker, migration prompts — survives the rebuild.
  home.activation.codexConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    codexConfig="$HOME/.codex/config.toml"
    mkdir -p "$(dirname "$codexConfig")"

    # A symlink left by an earlier generation has to go first, otherwise the
    # write below would follow it into the (read-only) nix store.
    if [ -L "$codexConfig" ]; then
      rm -f "$codexConfig"
    fi

    codexOld='{}'
    if [ -s "$codexConfig" ]; then
      codexOld=$(${pkgs.remarshal}/bin/toml2json < "$codexConfig") || {
        echo "codex: $codexConfig is not valid TOML, regenerating it" >&2
        codexOld='{}'
      }
    fi

    ${pkgs.jq}/bin/jq -n \
      --argjson old "$codexOld" \
      --argjson new "$(${pkgs.remarshal}/bin/toml2json < ${managedConfig})" \
      '($old | delpaths([$new | keys_unsorted[] | [.]])) + $new' \
      | ${pkgs.remarshal}/bin/json2toml > "$codexConfig.new"

    mv -f "$codexConfig.new" "$codexConfig"
    chmod 600 "$codexConfig"
  '';
}
