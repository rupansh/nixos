{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.claude-code;
  settingsPath = "${cfg.configDir}/settings.json";

  # The settings.json home-manager would have symlinked into place. We keep the
  # generated derivation but install it ourselves, see the activation script.
  managedSettings = config.home.file.${settingsPath}.source;

  statusline = pkgs.writeShellApplication {
    name = "claude-statusline";
    runtimeInputs = with pkgs; [
      git
      jq
    ];
    text = builtins.readFile ./claude-code/statusline.sh;
  };
in
{
  programs.claude-code = {
    enable = true;
    enableMcpIntegration = true;

    skills = import ./skills;

    settings.statusLine = {
      type = "command";
      command = lib.getExe statusline;
    };
  };

  # settings.json must NOT be a read-only nix-store symlink: Claude Code writes
  # to it itself (`/effort`, `/model`, the auto-mode opt-in, ...), and those
  # writes would fail against the store.
  home.file.${settingsPath}.enable = false;

  # Install it as a real file instead, merging rather than overwriting: Nix
  # fully owns every top-level key it sets, while anything Claude Code wrote
  # for itself survives the rebuild. Same approach as codex.nix.
  home.activation.claudeCodeSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    claudeSettings=${lib.escapeShellArg settingsPath}
    mkdir -p "$(dirname "$claudeSettings")"

    # A symlink left by an earlier generation has to go first, otherwise the
    # write below would follow it into the (read-only) nix store.
    if [ -L "$claudeSettings" ]; then
      rm -f "$claudeSettings"
    fi

    claudeOld='{}'
    if [ -s "$claudeSettings" ]; then
      claudeOld=$(${pkgs.jq}/bin/jq -c . "$claudeSettings") || {
        echo "claude-code: $claudeSettings is not valid JSON, moving it to $claudeSettings.invalid" >&2
        mv -f "$claudeSettings" "$claudeSettings.invalid"
        claudeOld='{}'
      }
    fi

    ${pkgs.jq}/bin/jq -n \
      --argjson old "$claudeOld" \
      --slurpfile new ${managedSettings} \
      '$new[0] as $new | ($old | delpaths([$new | keys_unsorted[] | [.]])) + $new' \
      > "$claudeSettings.new"

    mv -f "$claudeSettings.new" "$claudeSettings"
  '';
}
