{ config, pkgs, lib, ... }: let
  cfg = config.programs.nixpak-flatpak-wrapper;
  fmt = pkgs.formats.toml {};
  wrapperPackage = import ./pkg.nix {
    inherit pkgs lib;
    flatpak-pkg = cfg.package;
  };
in {
  options.programs.nixpak-flatpak-wrapper = {
    rawStructuredConfig = lib.mkOption {
      type = lib.types.attrsOf (lib.types.listOf (lib.types.submodule {
      options = {
        app_id = lib.types.str;
        bind = lib.types.submodule {
          options = {
            rw = lib.types.listOf lib.types.str;
            ro = lib.types.listOf lib.types.str;
          };
        };
      };
      }));
      default = {};
    };
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.flatpak;
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      wrapperPackage
    ];
    services.dbus.packages = [ wrapperPackage ];
    systemd.packages = [ wrapperPackage ];

    environment.etc."nixpak-flatpak-wrapper.toml".source = fmt.generate "nixpak-flatpak-wrapper.toml" cfg.rawStructuredConfig;
  };

}