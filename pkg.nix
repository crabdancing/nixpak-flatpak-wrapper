{ pkgs, lib }:

pkgs.rustPlatform.buildRustPackage rec {
  pname = "flatpak";
  version = "0.1.0";

  src = lib.cleanSource ./.;  # Refers to the local directory

  # cargoSha256 = "0000000000000000000000000000000000000000000000000000";  # Placeholder hash
  # cargoHash = lib.fakeHash;

  # Include additional build inputs and environment variables if needed
  buildInputs = [ pkgs.makeWrapper /* your dependencies, e.g., pkgs.openssl */ ];
  cargoBuildFlags = [ /* custom build flags if any */ ];

          postInstall = ''
            wrapProgram $out/bin/flatpak \
              --prefix PATH : ${pkgs.flatpak}/bin/
          '';
  meta = {
    description = "A wrapper for flatpak to make xdg-portal service compatible with nixpak";
    homepage = "https://github.com/alxpettit/nixpak-flatpak-wrapper";
    license = pkgs.lib.licenses.lgpl3Only;
    # Override other flatpak in the PATH dance uwu
    meta.priority = -10;
    # maintainers = with pkgs.lib.maintainers; [ /* your name */ ];
  };
}

