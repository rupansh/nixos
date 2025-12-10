{ ... }:
{
  programs.git = {
    enable = true;
    settings = {
      user.email = "rupanshsekar@hotmail.com";
      user.name = "rupansh";
      init.defaultBranch = "master";
      color.ui = "auto";
      pull.rebase = true;
    };
    includes = [
      {
        condition = "gitdir:~/hot-or-n/";
        contents = {
          url."git@github-rupansh-gob:".insteadOf = "https://github.com/";
        };
      }
      {
        condition = "gitdir:~/";
        contents = {
          url."git@github-rupansh:" = {
            insteadOf = [
              "https://github.com/"
              "ssh://git@github.com/"
            ];
          };
        };
      }
    ];
  };
}
