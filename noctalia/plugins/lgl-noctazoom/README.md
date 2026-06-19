# NoctaZoom

Noctalia plugin that launches `hyprmag` and exposes it through Noctalia IPC.

## Install

Symlink this folder into your Noctalia plugins directory:

```bash
ln -s /home/lgl/projects/hyprmag/lgl-noctazoom ~/.config/noctalia/plugins/lgl-noctazoom
```

Then reload Noctalia.

## Configure

Set the `command` field in plugin settings to your `hyprmag` binary if `hyprmag` is not on `PATH`.

Examples:

```text
hyprmag
/home/lgl/projects/hyprmag/build/hyprmag
```

Default lens settings:

- `shape`: `rounded-rect`
- `width`: `500`
- `height`: `200`
- `scale`: `4`

## IPC

Toggle:

```bash
qs -c noctalia-shell ipc call plugin:lgl-noctazoom toggle
```

Start:

```bash
qs -c noctalia-shell ipc call plugin:lgl-noctazoom start
```

Stop:

```bash
qs -c noctalia-shell ipc call plugin:lgl-noctazoom stop
```

Change size:

```bash
qs -c noctalia-shell ipc call plugin:lgl-noctazoom setSize 500 200
```

Change scale:

```bash
qs -c noctalia-shell ipc call plugin:lgl-noctazoom setScale 4.5
```

## Notes

This plugin is a launcher/controller for `hyprmag`; it does not reimplement magnification in QML.
