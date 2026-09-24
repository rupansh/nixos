{ ... }:
{
  programs.claude-code = {
    enable = true;
    enableMcpIntegration = true;

    skills = import ./skills;
  };
}
