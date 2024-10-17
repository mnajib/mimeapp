{
  description = "Haskell project to manage mimeapps.list and .desktop files";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable"; # Use the latest nixpkgs
    flake-utils.url = "github:numtide/flake-utils";       # Utility functions for flakes
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        # Define the Haskell package with GHC and Cabal support
        project = pkgs.haskellPackages.callCabal2nix "mime-manager" ./. {};
      in
      {
        # Package configuration (so you can use 'nix build')
        packages.default = project;

        # DevShell for the project (for 'nix develop')
        devShell = pkgs.mkShell {
          nativeBuildInputs = [
            pkgs.ghc        # GHC compiler for Haskell
            pkgs.cabal-install # Cabal for building Haskell projects
            pkgs.git        # Git for version control
            pkgs.dialog     # ncurse for CLI
            #pkgs.perl540Packages.FileMimeInfo
          ];
        };

        # Run the program using 'nix run'
        apps.mime-manager = {
          type = "app";
          program = "${project}/bin/mime-manager";
        };
      });
}

