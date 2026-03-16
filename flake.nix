{
  description = "typst + rust development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      rust-overlay,
    }:
    let
      systems = nixpkgs.lib.platforms.unix;
      eachSystem =
        f:
        nixpkgs.lib.genAttrs systems (
          system:
          f (
            import nixpkgs {
              inherit system;
              config = { };
              overlays = [
                rust-overlay.overlays.default
                self.overlays.default
              ];
            }
          )
        );
      fs = nixpkgs.lib.fileset;
      sources = map toString (fs.toList (fs.fileFilter (f: f.hasExt "typ") ./examples));
      names = map (s: builtins.elemAt (builtins.match ".*/([^/]+)\\.typ$" s) 0) sources;
    in
    {
      packages = eachSystem (
        pkgs:
        let
          inherit (pkgs.lib.fileset) toSource unions;
          tanki = pkgs.buildTypstPackage {
            pname = "tanki";
            version = "0.0.1";
            src = toSource {
              root = ./.;
              fileset = fs.intersection (fs.gitTracked ./.) (unions [
                ./lib
                ./typst.toml
              ]);
            };
          };
          tanki-rs = pkgs.rustPlatform.buildRustPackage {
            pname = "tanki-rs";
            version = "0.0.1";
            src = fs.toSource {
              root = ./rs;
              fileset = fs.intersection (fs.gitTracked ./rs) (
                fs.unions [
                  ./rs/Cargo.toml
                  ./rs/Cargo.lock
                  (fs.fileFilter (f: f.hasExt "rs") ./rs)
                ]
              );
            };
            cargoLock.lockFile = ./rs/Cargo.lock;
          };
        in
        {
          inherit tanki tanki-rs;
          default = tanki;
        }
      );

      devShells = eachSystem (pkgs: {
        default = pkgs.mkShellNoCC {
          packages = with pkgs; [
            typst
            typstyle
            rustToolchain
            pkg-config
            bacon
            rust-analyzer
          ];
          env = {
            RUST_BACKTRACE = 1;
            RUST_SRC_PATH = "${pkgs.rustToolchain}/lib/rustlib/src/rust/library";
          };
        };
      });

      overlays.default = _: prev: {
        rustToolchain = prev.rust-bin.stable.latest.default.override {
          extensions = [
            "rust-src"
            "rustfmt"
          ];
          targets = [ "wasm32-unknown-unknown" ];
        };
      };

      apps = eachSystem (
        pkgs:
        let
          watch-open =
            name:
            let
              input = "examples/${name}.typ";
              output = "examples/${name}.pdf";
            in
            pkgs.writeShellApplication {
              name = "typst-watch-open-${name}";
              text = ''
                (trap 'kill 0' SIGINT; 
                  ${pkgs.zathura}/bin/zathura "$PWD/${output}" &
                  ${pkgs.typst}/bin/typst watch ${input} --root .
                )
              '';
            };
          scripts = map (
            name:
            let
              p = watch-open name;
            in
            {
              inherit name;
              value = {
                type = "app";
                program = "${p}/bin/typst-watch-open-${name}";
              };
            }
          ) names;
        in
        (pkgs.lib.mapAttrs (_: drv: {
          type = "app";
          program = "${drv}${drv.passthru.exePath or "/bin/${drv.pname or drv.name}"}";
        }) self.packages.${pkgs.system})
        // pkgs.lib.listToAttrs scripts
        // {
          default = (builtins.elemAt scripts 0).value;
        }
      );
    };
}
