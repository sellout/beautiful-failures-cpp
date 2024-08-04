{
  description = "Ergonomic error handling in C++";

  nixConfig = {
    ## https://github.com/NixOS/rfcs/blob/master/rfcs/0045-deprecate-url-syntax.md
    extra-experimental-features = ["no-url-literals"];
    extra-substituters = ["https://cache.garnix.io"];
    extra-trusted-public-keys = [
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
    ];
    ## Isolate the build.
    registries = false;
    sandbox = "relaxed";
  };

  outputs = {
    bash-strict-mode,
    flake-utils,
    flaky,
    nixpkgs,
    self,
  }: let
    pname = "beautiful-failures";

    supportedSystems = flaky.lib.defaultSystems;
  in
    {
      schemas = {
        inherit
          (flaky.schemas)
          overlays
          homeConfigurations
          packages
          devShells
          projectConfigurations
          checks
          formatter
          ;
      };

      overlays.default = final: prev: {
        "${pname}" = self.packages.${final.system}.${pname};
      };

      homeConfigurations =
        builtins.listToAttrs
        (builtins.map
          (flaky.lib.homeConfigurations.example self
            [({pkgs, ...}: {home.packages = [pkgs.${pname}];})])
          supportedSystems);

      lib = {};
    }
    // flake-utils.lib.eachSystem supportedSystems (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [flaky.overlays.dependencies];
      };

      ## NB: This isn’t done in `pkgs` because we don’t want to rebuild the
      ##     world.
      clangPkgs = import nixpkgs {
        inherit system;
        config.replaceStdenv = {pkgs, ...}: pkgs.llvmPackages.stdenv;
      };

      src = pkgs.lib.cleanSource ./.;
    in {
      packages = {
        default = self.packages.${system}.${pname};

        "${pname}" =
          ## NB: This doesn’t use `checkdDrv` because of issues with libtoolize.
          ##    (“libtoolize: line 2775: debug_mode: unbound variable”).
          bash-strict-mode.lib.shellchecked pkgs
          (clangPkgs.stdenv.mkDerivation {
            inherit pname src;

            buildInputs = [
              pkgs.autoreconfHook
              pkgs.tl-expected
            ];

            version = "0.1.0";
          });
      };

      projectConfigurations =
        flaky.lib.projectConfigurations.default {inherit pkgs self;};

      devShells =
        self.projectConfigurations.${system}.devShells
        // {default = flaky.lib.devShells.default system self [] "";};

      checks =
        self.projectConfigurations.${system}.checks
        // {
          ## TODO: This doesn’t quite work yet.
          # c-lint =
          #   flaky.lib.checks.simple
          #   pkgs
          #   src
          #   "clang-tidy"
          #   [pkgs.llvmPackages.clang]
          #   ''
          #     ## TODO: Can we keep the compile-commands.json from the original
          #     ##       build? E.g., send it to a separate output, which we
          #     ##       depend on from this check. We also want it for clangd in
          #     ##       the devShell.
          #     make clean && bear -- make
          #     find "$src" \( -name '*.c' -o -name '*.cpp' -o -name '*.h' \) \
          #       -exec clang-tidy {} +
          #   '';
        };

      formatter = self.projectConfigurations.${system}.formatter;
    });

  inputs = {
    ## Flaky should generally be the source of truth for its inputs.
    flaky.url = "github:sellout/flaky";

    bash-strict-mode.follows = "flaky/bash-strict-mode";
    flake-utils.follows = "flaky/flake-utils";
    nixpkgs.follows = "flaky/nixpkgs";
  };
}
