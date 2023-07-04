{
  description = "Ergonomic error handling in C++";

  nixConfig = {
    # https://github.com/NixOS/rfcs/blob/master/rfcs/0045-deprecate-url-syntax.md
    extra-experimental-features = ["no-url-literals"];
    extra-trusted-public-keys = [
      "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g="
    ];
    extra-trusted-substituters = ["https://cache.garnix.io"];
    # Isolate the build.
    registries = false;
    sandbox = true;
  };

  outputs = inputs: let
    pname = "beautiful-failures";
  in
    {
      overlays.default = final: prev: {};

      homeConfigurations =
        builtins.listToAttrs
        (builtins.map
          (system: {
            name = "${system}-example";
            value = inputs.home-manager.lib.homeManagerConfiguration {
              pkgs = import inputs.nixpkgs {
                inherit system;
                overlays = [inputs.self.overlays.default];
              };

              modules = [
                {
                  # These attributes are simply required by home-manager.
                  home = {
                    homeDirectory = /tmp/${pname}-example;
                    stateVersion = "23.05";
                    username = "${pname}-example-user";
                  };
                }
              ];
            };
          })
          inputs.flake-utils.lib.defaultSystems);

      lib = {};
    }
    // inputs.flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import inputs.nixpkgs {inherit system;};

      src = pkgs.lib.cleanSource ./.;

      ## TODO: This _should_ be done with an overlay, but I can’t seem to avoid
      ##       getting infinite recursion with it.
      stdenv = pkgs.llvmPackages_16.stdenv;
    in {
      packages = {
        default = inputs.self.packages.${system}.${pname};

        "${pname}" =
          ## TODO: Doesn’t use `strict-bash` because `libtoolize` has some bad
          ##       behavior.
          inputs.bash-strict-mode.lib.shellchecked pkgs
          (stdenv.mkDerivation {
            inherit pname src;

            buildInputs = [
              pkgs.autoreconfHook
              pkgs.tl-expected
            ];

            version = "0.1.0";
          });
      };

      devShells.default =
        inputs.bash-strict-mode.lib.checkedDrv pkgs
        (pkgs.mkShell.override {inherit stdenv;} {
          inputsFrom =
            builtins.attrValues inputs.self.checks.${system}
            ++ builtins.attrValues inputs.self.packages.${system};

          nativeBuildInputs = [
            # https://github.com/rizsotto/Bear
            pkgs.bear
            # Nix language server,
            # https://github.com/oxalica/nil#readme
            pkgs.nil
            # Bash language server,
            # https://github.com/bash-lsp/bash-language-server#readme
            pkgs.nodePackages.bash-language-server
          ];
        });

      checks = {
        clang-format =
          inputs.bash-strict-mode.lib.checkedDrv pkgs
          (stdenv.mkDerivation {
            inherit src;

            name = "clang-format";

            buildPhase = ''
              runHook preBuild
              shopt -s globstar
              clang-format --Werror --dry-run **/*.h **/*.cpp
              runHook postBuild
            '';

            installPhase = ''
              runHook preInstall
              mkdir -p "$out"
              runHook preInstall
            '';
          });

        nix-fmt =
          inputs.bash-strict-mode.lib.checkedDrv pkgs
          (stdenv.mkDerivation {
            inherit src;

            name = "nix fmt";

            nativeBuildInputs = [inputs.self.formatter.${system}];

            buildPhase = ''
              runHook preBuild
              alejandra --check .
              runHook postBuild
            '';

            installPhase = ''
              runHook preInstall
              mkdir -p "$out"
              runHook preInstall
            '';
          });
      };

      # Nix code formatter, https://github.com/kamadorueda/alejandra#readme
      formatter = pkgs.alejandra;
    });

  inputs = {
    bash-strict-mode = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:sellout/bash-strict-mode";
    };

    flake-utils.url = "github:numtide/flake-utils";

    home-manager = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:nix-community/home-manager/release-23.05";
    };

    nixpkgs.url = "github:NixOS/nixpkgs/release-23.05";
  };
}
