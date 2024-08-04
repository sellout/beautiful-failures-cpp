# Beautiful Failures (for C++)

[![built with garnix](https://img.shields.io/endpoint?url=https%3A%2F%2Fgarnix.io%2Fapi%2Fbadges%2Fsellout%2Fbeautiful-failures-cxx)](https://garnix.io)

Ergonomic error handling in C++

An ergonomic API for handling software failures.

## usage

It’s common for failure types to grow as they move up the call stack, and `std::variant` is the usual tool for this. As such, this library includes some additional helpers in ./src/failures/variant.h

In particular, `variant_cast` can be used to cast a variant to another variant that contains at least all the types in the original variant.

## development environment

We recommend the following steps to make working in this repository as easy as possible.

### `direnv allow`

This command ensures that any work you do within this repository happens within a consistent reproducible environment. That environment provides various debugging tools, etc. When you leave this directory, you will leave that environment behind, so it doesn’t impact anything else on your system.

### `git config --local include.path ../.cache/git/config`

This will apply our repository-specific Git configuration to `git` commands run against this repository. It’s lightweight (you should definitely look at it before applying this command) – it does things like telling `git blame` to ignore formatting-only commits.

## building & development

Especially if you are unfamiliar with the C++ ecosystem, there is a Nix flake build.

### if you have `nix` installed

`nix build` will build the project and run tests.

`nix flake check` will validate the state of the repository – formatting, linting, etc.

`nix develop` will put you into an environment where the traditional build tooling works. If you also have `direnv` installed, then you should automatically be in that environment when you're in a directory in this project.

### traditional build

You can build this project with GNU Autotools

```bash
autoreconf
./configure
make
```

## versioning

In the absolute, almost every change is a breaking change. This section describes how we mitigate that to offer minor updates and revisions.

## comparisons

Other projects similar to this one, and how they differ.

### `tl::expected` (eventually `std::expected`)

Beautiful Failures depends on this type, but on its own it doesn’t carry enough of the semantics of error handling.
