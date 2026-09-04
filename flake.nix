{
  description = "CodeRabbit CLI packaged as a Nix flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        version = "0.7.6";

        sources = {
          "x86_64-linux" = {
            platform = "linux-x64";
            hash = "sha256-hToXJ2CasP8fVoY/pt56zz3lk6bcG9f5GjLxHFck/8k=";
          };
          "aarch64-linux" = {
            platform = "linux-arm64";
            hash = "sha256-InBkGmMUvvDaMuWQPdxt5iZTVJYvfPZR/FgaSpHyJEc=";
          };
          "x86_64-darwin" = {
            platform = "darwin-x64";
            hash = "sha256-HGJC3sigmD/3CEK8HQ6MiI0akrGtgK+5acAMlMSCpwQ=";
          };
          "aarch64-darwin" = {
            platform = "darwin-arm64";
            hash = "sha256-+XDmCOODEU4e3yFO6nGpnWYE6h3QnAHnVO5rjUuFLLE=";
          };
        };

        src = sources.${system} or (throw "unsupported system: ${system}");

        coderabbit = pkgs.stdenv.mkDerivation {
          pname = "coderabbit";
          inherit version;

          src = pkgs.fetchurl {
            url = "https://cli.coderabbit.ai/releases/${version}/coderabbit-${src.platform}.zip";
            inherit (src) hash;
          };

          nativeBuildInputs = [ pkgs.unzip ]
            ++ pkgs.lib.optional pkgs.stdenv.isLinux pkgs.autoPatchelfHook;

          buildInputs = pkgs.lib.optionals pkgs.stdenv.isLinux [
            pkgs.stdenv.cc.cc.lib
          ];

          dontStrip = true;
          dontPatchELF = false;

          unpackPhase = ''
            runHook preUnpack
            unzip $src
            runHook postUnpack
          '';

          installPhase = ''
            runHook preInstall
            install -Dm755 coderabbit $out/bin/coderabbit
            ln -s coderabbit $out/bin/cr
            runHook postInstall
          '';

          meta = with pkgs.lib; {
            description = "CodeRabbit CLI — AI code review from the terminal";
            homepage = "https://www.coderabbit.ai/cli";
            license = licenses.unfree;
            mainProgram = "coderabbit";
            platforms = builtins.attrNames sources;
          };
        };
      in {
        packages.default = coderabbit;
        packages.coderabbit = coderabbit;

        apps.default = {
          type = "app";
          program = "${coderabbit}/bin/coderabbit";
        };
      });
}
