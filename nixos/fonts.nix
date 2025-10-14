{ pkgs, ... }:
{
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    fira-code
    fira-code-symbols
    nerd-fonts.jetbrains-mono
  ];
}
