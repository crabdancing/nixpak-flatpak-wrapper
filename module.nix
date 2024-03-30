{ config, pkgs, lib, ... }: let
  cfg = config.programs.nixpak-flatpak-wrapper;
  fmt = pkgs.formats.toml {};
  wrapperPackage = import ./pkg.nix {
    inherit pkgs lib;
    flatpak-pkg = cfg.package;
  };
  permissionType = lib.types.submodule {
    options = {
      app_id = lib.mkOption {
        type = lib.types.str;
        description = "Application identifier";
      };
      bind = lib.mkOption {
        type = lib.types.submodule {
          options = {
            rw = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [];
              description = "Directories to bind read-write";
            };
            ro = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [];
              description = "Directories to bind read-only";
            };
          };
        };
        description = "Bind permissions";
      };
    };
  };
in {
  options.programs.nixpak-flatpak-wrapper = {
    settings = lib.mkOption {
      type = lib.types.submodule {
        options = {
          perms = lib.mkOption {
            type = lib.types.listOf permissionType;
            default = [];
            description = "List of permissions for applications";
          };
        };
      };
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

    environment.etc."nixpak-flatpak-wrapper.toml".source = fmt.generate "nixpak-flatpak-wrapper.toml" cfg.settings;
  };

}