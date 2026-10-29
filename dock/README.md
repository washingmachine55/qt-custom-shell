# Niri macOS-style dock for Quickshell

A self-contained Quickshell component set for niri. Copy these files into your project and integrate `Dock.qml` / `Niri.qml` into your existing shell entry point.

## Files

- `DockConfig.qml`: pinned apps, placement, sizing and hide delay.
- `Niri.qml`: starts `niri msg --json event-stream`, parses window events, exposes windows and focus.
- `Dock.qml`: pinned + running app grouping, icon fallback, click-to-focus / launch.
- `DockPanel.qml`: example `PanelWindow` wrapper with placement, edge sensor and auto-hide.
- `main.qml`: standalone example entry point.

## Requirements

- Quickshell with `Quickshell.Io`, `Quickshell.Widgets`, and `Quickshell.Wayland`
- niri with `niri msg --json event-stream`
- `gtk-launch` for launching apps by desktop-file ID

## Run standalone

```sh
quickshell --config /path/to/niri-macdock
```

The config directory should contain `main.qml` and the other QML files.

## Configure

Edit `DockConfig.qml`. Set `edge` to `bottom`, `top`, `left`, or `right`. Update `pinnedApps` to match your installed applications. `appId` must match the `app_id` returned by:

```sh
niri msg --json windows | jq
```

`desktopId` is the desktop-entry ID without the `.desktop` suffix. `customIcon` may be an absolute file path or URL; if empty, the icon theme lookup uses `icon`.

## Notes

Niri IPC payload shapes can differ across versions. This implementation supports common tagged event forms and refreshes the full window list after events when necessary. Test against your installed niri version before relying on it.

This is an MVP, not a full reproduction of every macOS Dock feature. The auto-hide sensor and panel geometry may need small adjustments depending on Quickshell/niri versions and your monitor layout.
