{ config, pkgs, lib, ... }:

{
  programs.mcp.enable = true;

  mcp-servers.programs = {
    playwright.enable = true;
  };

  programs.claude-code = {
    enable = true;
    enableMcpIntegration = true;
  };
}
