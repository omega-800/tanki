# tAnki

A typst plugin + rust binary to programmatically generate anki decks from typst sourcecode.

This implementation is quick and dirty but it works. Maybe a cleaner implementation will follow. Maybe not. Deal with it.

## usage

### typst package

This package isn't in the official repository yet. You either have to clone this repo and include it in your typst project as a local import or add it to the TYPST_PACKAGE_PATH (for nix users: see flake as described below).

#### functions

```typst
#import "@local/tanki:0.0.1" as ta

#let did = 1234
#ta.add-deck("bigbrain", "this will make me smarter than einstein", id: did)
#let note = ta.add-note.with(deck: did) 

#note("Who is the most handsome developer on this planet?", "omega-800")
```

See [examples](./examples/main.typ) for more examples.

#### show rule

```typst
#import "@local/tanki:0.0.1" as ta

#show: ta.tanki-doc.with(deck: ta.deck(name: "Wow this is so much easier"))

= Headings as tags are still a bit buggy just so you know

#ta.start-note()
Who is the most handsome developer on this planet?
#ta.start-field()
omega-800
#ta.end-note()
```

See [show rule examples](./examples/show-rule.typ) for more examples.

### binary

> [!IMPORTANT]  
> Due to the typst html output not being fully implemented yet, math equations only work when using the 
> [mathml fork](https://github.com/mkorje/typst/tree/mathml). Be sure to override your path with 
> `PATH="/my/path/of/typst-mathml/bin:$PATH"` or launch tanki-rs with the path prefixed. If you want to use this in 
> conjunction with nix, see steps below

```sh
tanki-rs <path-to-typst-file> [typst-args]
# eg
PATH="/my/path/of/typst-mathml/bin:$PATH" tanki-rs my-document.typ
# or using nix
nix run github:omega-800/tanki#tanki-rs -- my-document.typ
```

#### nix

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    tanki = {
      url = "github:omega-800/tanki";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, tanki, ... }:
    {
      devShells.x86_64-linux.default =
        let
          pkgs = import nixpkgs {
            system = "x86_64-linux";
            overlays = [
              tanki.overlays.typst-mathml
              tanki.overlays.tanki
            ];
          };
        in
        pkgs.mkShellNoCC {
          packages = [ pkgs.tanki-rs pkgs.typst-mathml ];
          PATH = "${pkgs.typst-mathml}/bin:$PATH";

          TYPST_PACKAGE_PATH = "${pkgs.lib.escapeShellArg (
            pkgs.linkFarm "unpublished-typst-packages" {
              "local/tanki/0.0.1" = tanki;
            }
          )}";
        };
    };
}
```
