{config, pkgs, ...}: {
  project = {
    name = "beautiful-failures";
    summary = "Ergonomic error handling in C++";

    devPackages = [
      pkgs.bear # https://github.com/rizsotto/Bear
    ];
  };

  ## dependency management
  services.renovate.enable = true;

  ## development
  programs = {
    direnv.enable = true;
    # This should default by whether there is a .git file/dir (and whether it’s
    # a file (worktree) or dir determines other things – like where hooks
    # are installed.
    git.enable = true;
  };

  ## formatting
  editorconfig.enable = true;
  imports = [./clang-format.nix];
  programs = {
    treefmt.enable = true;
    vale = {
      enable = true;
      excludes = [
        "*/Makefile.am"
        "./.github/settings.yml"
        "./configure.ac"
      ];
      vocab.${config.project.name}.accept = [
        "Autotools"
        "GNU"
        "implicator"
        "superset"
      ];
    };
  };

  ## CI
  services.garnix = {
    enable = true;
    ## TODO: Remove once garnix-io/garnix#285 is fixed.
    builds.exclude = ["homeConfigurations.x86_64-darwin-example"];
  };

  ## publishing
  services = {
    flakehub.enable = true;
    github.enable = true;
  };
}
