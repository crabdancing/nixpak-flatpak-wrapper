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

[[perms]]
app_name = "org.mozilla.firefox"
bind_rw = [
  "~/Downloads"
]
bind_ro = []
```

It records what happens in `~/.local/share/nixpak-flatpak-wrapper/nixpak-flatpak-wrapper.log` for ease of debugging. This is because a drop-in wrapper/replacement should not print warning/error messages the original app would not have, in case it breaks someone's parsing.