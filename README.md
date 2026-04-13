# fedirinoc

A post-install bash script that sets up [niri](https://github.com/niri-wm/niri) + [Noctalia](https://noctalia.dev) on a minimal Fedora install.

---

> [!WARNING]
> **Work in progress. Not tested on real hardware.**

---

## Concept

Fedora minimal (TTY) → run `install.sh` → type `niri-session` → niri + Noctalia

No display manager. No greeter. Lightweight by design.

## What it does

1. Enables repos (avengemedia/danklinux COPR + terra)
2. Installs niri, Noctalia, and required deps
3. Appends Noctalia startup config to `~/.config/niri/config.kdl`
4. Writes xdg-portal config
5. Enables PipeWire user session
6. Prints post-install instructions

## What Noctalia handles

These are not configured by the script — Noctalia manages them internally:

| Feature | Handler |
|---|---|
| Wallpaper | Noctalia built-in |
| Notifications | Noctalia built-in |
| Lock screen | Noctalia built-in |
| Night light | Noctalia NightLightService |
| Status bar | Noctalia built-in |
| App launcher | Noctalia built-in |

## After install

Log in at TTY, then:

```bash
niri-session
```

Display config (run inside niri after first launch):
```bash
niri msg outputs
# Note your output name and mode
# Edit ~/.config/niri/config.kdl — uncomment the OUTPUT CONFIGURATION section
```

## Known Issues

| Issue | Status | Workaround |
|---|---|---|
| Screencasting broken | Known niri bug [#2399](https://github.com/niri-wm/niri/issues/2399) | Restart portals manually |
| Suspend → red screen | Known niri + Fedora GPU bug | Avoid suspend |
| Display output config | Requires running niri | Manual step post-install |
| `power-profiles-daemon` conflicts with `tuned-ppd` | Fedora minimal conflict | Excluded from install |

## Docs

- [`packages.md`](docs/packages.md) — full package list with rationale
- [`niri-config.md`](docs/niri-config.md) — niri config.kdl reference
- [`install-sequence.md`](docs/install-sequence.md) — install phase reference
- [`open-questions.md`](docs/open-questions.md) — unresolved items

## License

[MIT](LICENSE)
