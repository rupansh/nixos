{ ... }:
{
  # Shared MCP registry. mcp-servers-nix feeds `programs.mcp.servers`, which every
  # agent CLI with `enableMcpIntegration = true` (claude-code, codex, opencode)
  # renders into its own config format. Declare servers once, here.
  programs.mcp.enable = true;

  mcp-servers.programs = {
    playwright.enable = true;
    nixos.enable = true;
  };
}
