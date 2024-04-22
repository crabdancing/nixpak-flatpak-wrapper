{ flatpak-pkg, pkgs, lib }:
let 
  rustPkg = pkgs.rustPlatform.buildRustPackage rec {
    pname = "nixpak-flatpak-wrapper";
    version = "0.1.0";

    src = lib.cleanSource ./.; 
    buildInputs = [ pkgs.makeWrapper ];
    cargoBuildFlags = [ ];
    cargoLock.lockFile = ./Cargo.lock;
    meta = {
      description = "A wrapper for flatpak to make xdg-portal service compatible with nixpak";
      homepage = "https://github.com/crabdancing/nixpak-flatpak-wrapper";
      license = pkgs.lib.licenses.lgpl3Only;
    };
  };
in 
(pkgs.symlinkJoin {
    name = "flatpak";
    meta.mainProgram = "flatpak";
    paths = [ pkgs.flatpak rustPkg ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      mv "$out/bin/flatpak" "$out/bin/flatpak-raw"
      ln -s "$out/bin/nixpak-flatpak-wrapper" "$out/bin/flatpak"
    '';
  })


