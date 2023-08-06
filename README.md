# Beautiful Failures (for C++)

Ergonomic error handling in C++

An ergonomic API for handling software failures.

## usage

It is common for failure types to grow as they move up the call stack, and `std::variant` is the usual tool for this. As such, this library includes some additional helpers in ./src/failures/variant.h

In particular, `variant_cast` can be used to cast a variant to another variant that contains at least all the types in the original variant.

## building & development

Especially if you are unfamiliar with the C++ ecosystem, there is a Nix flake build.

### if you have `nix` installed

`nix build` will build the project and run tests.

`nix flake check` will validate the state of the repo – formatting, linting, etc.

`nix develop` will put you into an environment where the traditional build tooling works. If you also have `direnv` installed, then you should automatically be in that environment when you're in a directory in this project.

### traditional build

This project can be built with GNU Autotools
```bash
autoreconf
./configure
make
```

## versioning

In the absolute, almost every change is a breaking change. This section describes how we mitigate that to provide minor updates and revisions.

{{versioning-description}}

## comparisons

Other projects similar to this one, and how they differ.

### `tl::expected` (eventually `std::expected`)

Beautiful Failures depends on this type, but on its own it doesn’t carry enough of the semantics of error handling.
