{ lib }: with lib; {
  type = "attrs";
  description = "Configuration for nixpak-flatpak-wrapper";
  options = {
    enable_log = {
      type = "bool";
      default = false;
      description = "Enable logging";
    };
    perms = {
      type = listOf (submodule {
        options = {
          app_id = {
            type = "string";
            description = "Flatpak application ID";
          };
          bind = {
            type = "attrs";
            description = "Binding permissions";
            options = {
              rw = {
                type = "listOf str";
                default = [];
                description = "Read-write bound paths";
              };
              ro = {
                type = "listOf str";
                default = [];
                description = "Read-only bound paths";
              };
            };
          };
        };
      });
      default = [];
      description = "Permissions configuration for Flatpak applications";
    };
  };
}

