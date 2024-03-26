{ config, pkgs, lib, ... }: let
  cfg = config.programs.nixpak-flatpak-wrapper;
  fmt = pkgs.formats.toml {};
  package = import ./pkg.nix { inherit pkgs lib; };
  wrapperPackage = pkgs.symlinkJoin {
    name = "flatpak";
    meta.mainProgram = "flatpak";
    paths = [ pkgs.flatpak ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postInstall = ''
      mv "$out/bin/flatpak" "$out/bin/flatpak-raw"
      cp "${package}/bin/flatpak" "$out/bin/flatpak"
    '';
  };

in {
  options.programs.nixpak-flatpak-wrapper = {
    rawStructuredConfig = lib.mkOption {
      # TODO: schema?
      default = {};
    };
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      wrapperPackage

    ];
    environment.etc."nixpak-flatpak-wrapper.toml".source = fmt.generate "nixpak-flatpak-wrapper.toml" cfg.rawStructuredConfig;
  };

}