{ pkgs, lib }:

pkgs.rustPlatform.buildRustPackage rec {
  pname = "flatpak";
  version = "0.1.0";

  src = lib.cleanSource ./.; 
  buildInputs = [ pkgs.makeWrapper ];
  cargoBuildFlags = [ ];
  cargoLock.lockFile = ./Cargo.lock;
  postInstall = ''
    wrapProgram $out/bin/flatpak \
      --prefix PATH : ${pkgs.flatpak}/bin/
  '';
  meta = {
    description = "A wrapper for flatpak to make xdg-portal service compatible with nixpak";
    homepage = "https://github.com/alxpettit/nixpak-flatpak-wrapper";
    license = pkgs.lib.licenses.lgpl3Only;
  };
}

