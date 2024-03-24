Glue to wrap `flatpak`, as part of a mischievous scam, tricking `xdg-desktop-portal` into letting us have decent [delcaratively managed containerization on NixOS](https://github.com/nixpak/nixpak/).


I mean, it wasn't like [upstream was gonna stop bikeshedding](https://github.com/flatpak/xdg-desktop-portal/pull/741) on this any time soon.

Config is stored at `/etc/nixpak-flatpak-wrapper.toml` and can be declaratively managed through structured data. Might someday add a module to make that easier.

The schema is as such:

```toml
[[perms]]
app_name = "org.chromium.Chromium"
bind_rw = [
  "~/Downloads"
]
bind_ro = []
```