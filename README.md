Glue to wrap `flatpak`, as part of a mischievous scam, tricking `xdg-desktop-portal` into letting us have decent [declaratively managed containerization on NixOS](https://github.com/nixpak/nixpak/).

I mean, it wasn't like [upstream was gonna stop bikeshedding](https://github.com/flatpak/xdg-desktop-portal/pull/741) on this any time soon.

## Features 

- Theoretically kind of robust (IDK, I haven't seen it misbehave yet.)
- Detect misconfigurations & prevent infinite loops (i.e., failure modes where the wrapper is calling itself because it is the first `flatpak` on its own PATH)
- Most failure modes will simply transparently call flatpak to avoid bricking flatpak
- Comes with a binary name deliberately colliding with `flatpak`, and a derivation set with a priority of `-10` in the hopes of always overriding flatpak.
- Contains built-in Nix wrapper to ensure the PATH always begins with `${pkgs.flatpak}/bin/` bin, to prevent configuration mistakes.
- Logs its experiences in a wondrous diary of adventure so that you can see why, when something goes wrong.
- Centrally managed with a TOML config file, which is hopefully kind of easy to declaratively manage.


## Usage


Config is stored at `/etc/nixpak-flatpak-wrapper.toml` and can be declaratively managed through structured data. Might someday add a module to make that easier.

The schema is as such:

```toml
[[perms]]
app_name = "org.chromium.Chromium"
bind_rw = [
  "~/Downloads"
]
bind_ro = []

[[perms]]
app_name = "org.mozilla.firefox"
bind_rw = [
  "~/Downloads"
]
bind_ro = []
```

It records what happens in `~/.local/share/nixpak-flatpak-wrapper/nixpak-flatpak-wrapper.log` for ease of debugging. This is because a drop-in wrapper/replacement should not print warning/error messages the original app would not have, in case it breaks someone's parsing.
