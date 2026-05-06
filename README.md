# coderabbit-nix-flake

Nix flake for the [CodeRabbit CLI](https://www.coderabbit.ai/cli).

Wraps the prebuilt `coderabbit` binary from `cli.coderabbit.ai/releases` and
patches the ELF interpreter so it runs on NixOS.

> This flake is not affiliated with CodeRabbit. The CLI is proprietary;
> running it constitutes acceptance of [CodeRabbit's Terms of Service](https://www.coderabbit.ai/terms-of-service).

> **Heads up:** the flake is pinned to a specific upstream version. When
> CodeRabbit ships a new release, the pinned version may stop working
> (e.g. if the old zip is removed from their CDN). A daily CI job opens a
> PR with the new version + hashes, usually merged within a day — once
> merged, run `nix flake update coderabbit` in your own flake to pick it
> up.

## Try it

```sh
nix run github:mariovisnjic/coderabbit-nix-flake -- auth login
```

## Use as a flake input

```nix
{
  inputs.coderabbit.url = "github:mariovisnjic/coderabbit-nix-flake";
  inputs.coderabbit.inputs.nixpkgs.follows = "nixpkgs";

  outputs = { self, nixpkgs, coderabbit, ... }: {
    nixosConfigurations.<host> = nixpkgs.lib.nixosSystem {
      modules = [
        ({ pkgs, ... }: {
          environment.systemPackages = [
            coderabbit.packages.${pkgs.system}.default
          ];
        })
      ];
    };
  };
}
```

After rebuild:

```sh
cr auth login
cr review
```

## Bumping the version

1. Update `version` in `flake.nix`.
2. For each platform zip, recompute the hash:
   ```sh
   nix hash file --type sha256 <(curl -fsSL https://cli.coderabbit.ai/releases/<ver>/coderabbit-<plat>.zip)
   ```
3. Replace the four `hash = "sha256-...";` lines.

Supported systems: `x86_64-linux`, `aarch64-linux`, `x86_64-darwin`, `aarch64-darwin`.
