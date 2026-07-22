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

        version = "0.7.0";

        sources = {
          "x86_64-linux" = {
            platform = "linux-x64";
            hash = "sha256-o3A45u+lzFkTr2rO1VClgtnJzbkbSgSG+dNQ7wT6qqw=";
          };
          "aarch64-linux" = {
            platform = "linux-arm64";
            hash = "sha256-Pj3vFdp/F9YB/5Dj0dge2TtJicaudQngWSbWBmmBWNQ=";
          };
          "x86_64-darwin" = {
            platform = "darwin-x64";
            hash = "sha256-qgpH/wGqhJ1h7tJ0ZPTuI2Afat1QwBRQwWiaWAKXDHY=";
          };
          "aarch64-darwin" = {
            platform = "darwin-arm64";
            hash = "sha256-VTmRD9ZHRTUbRB0zCadn4WtJphkWzFl4PQm3SOKkgz4=";
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
