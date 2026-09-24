{
  # Ships the `devenv` binary and sources `devenv hook fish` in fish's
  # interactiveShellInit, so entering a `devenv allow`-ed project dir drops
  # into `devenv shell` automatically (and `cd`-ing out leaves it again).
  programs.devenv = {
    enable = true;
    enableFishIntegration = true;
  };
}
