Glue to wrap `flatpak`, as part of a mischievous scam, tricking `xdg-desktop-portal` into letting us have decent [declaratively managed containerization on NixOS](https://github.com/nixpak/nixpak/).

I mean, it wasn't like [upstream was gonna stop bikeshedding](https://github.com/flatpak/xdg-desktop-portal/pull/741) on stuff like this any time soon.

## Features 

- Theoretically kind of robust (IDK, I haven't seen it misbehave yet.)
- Most failure modes will simply transparently call flatpak to avoid bricking flatpak
- Wraps the entirety of the `pkgs.flatpak` file set, transparently updating it with a replacement for the binary, renaming the old binary to `flatpak-raw`
- Easy-to-use module for drop-in reliable configuration & setup
- Contains built-in Nix wrapper to ensure the PATH always begins with `${pkgs.flatpak}/bin/` bin, to prevent configuration mistakes.
- Logs its experiences in a wondrous diary of adventure so that you can see why, when something goes wrong.
- Centrally managed with a TOML config file, which is hopefully kind of easy to declaratively manage.
- A schema-aware Nix configuration module, so that I will forget to update it when I make changes to the TOML config. :sob:
- Arguably overengineered, with questionable features such as tilda expansion.


## Usage

You can add it to your system flake `inputs` like so:

```nix
nixpak-flatpak-wrapper = {
  url = "github:alxpettit/nixpak-flatpak-wrapper";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

Once you've added the `nixosModules.default` to your system modules, configuration can happen like so:
```nix
programs.nixpak-flatpak-wrapper = {
  enable = true;
  settings = {
    perms = [
      {
        app_id = "org.chromium.Chromium";
        bind.rw = [
          "~/Downloads"
        ];
      }
      {
        app_id = "org.mozilla.firefox";
        bind.rw = [
          "~/Downloads"
        ];
      }
    ];
  };
};
```

## Internals

Config is stored at `/etc/nixpak-flatpak-wrapper.toml`

The schema is as such:

```toml
[[perms]]
app_id = "org.chromium.Chromium"
bind.rw = [
  "~/Downloads"
]
bind.ro = []

[[perms]]
app_id = "org.mozilla.firefox"
bind.rw = [
  "~/Downloads"
]
bind.ro = []
```

It records what happens in `~/.local/share/nixpak-flatpak-wrapper/nixpak-flatpak-wrapper.log` for ease of debugging. This is because a drop-in wrapper/replacement should not print warning/error messages the original app would not have, in case it breaks someone's parsing.
