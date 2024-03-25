# hideous, I know
{ nixpak-flatpak-wrapper }: { config, pkgs, lib, ... }: let
  cfg = config.programs.nixpak-flatpak-wrapper;
  fmt = pkgs.formats.toml {};
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
    
    ];
      environment.etc."nixpak-flatpak-wrapper.toml".source = fmt.generate "nixpak-flatpak-wrapper.toml" cfg.rawStructuredConfig;
  };

}