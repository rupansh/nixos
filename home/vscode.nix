{ pkgs, lib, ... }:
{
  programs.vscode.enable = true;
  programs.vscode.profiles.default = {
    enableUpdateCheck = false;
    enableExtensionUpdateCheck = false;
    userSettings = {
      "workbench.colorTheme" = "Shades of Purple (Super Dark)";
      "terminal.integrated.defaultProfile.linux" = "fish";
      "files.autoSave" = "afterDelay";
      "update.mode" = "none";
      "extensions.autoCheckUpdates" = false;

      "vim.useSystemClipboard" = true;

      "nix.enableLanguageServer" = true;
      "nix.serverPath" = "nil";
      "nix.serverSettings".nil = {
        formatting.command = [ "${lib.getExe pkgs.nixfmt-rfc-style}" ];
      };
    };
    extensions = pkgs.nix4vscode.forVscode [
      "ahmadawais.shades-of-purple"
      "rust-lang.rust-analyzer"
      "bradlc.vscode-tailwindcss"
      "vscodevim.vim"
      "jnoortheen.nix-ide"
      "anthropic.claude-code"
      "pbkit.vscode-pbkit"
    ];
  };
}
