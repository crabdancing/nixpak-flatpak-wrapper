{
  description = "Build a cargo project";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { nixpkgs, flake-utils, ... }:

    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
        nixpak-flatpak-wrapper = pkgs.callPackage ./pkg.nix;
      in
      {
  
        packages.default = nixpak-flatpak-wrapper;
        apps.default = flake-utils.lib.mkApp {
          drv = nixpak-flatpak-wrapper;
        };
      }) // {
      nixosModule = import ./module.nix;
    };
}
