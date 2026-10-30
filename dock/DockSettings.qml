pragma Singleton
import QtQuick
import Quickshell

// Edit this file to configure the dock. Changes hot-reload.
Singleton {
    // "bottom", "top", "left" or "right"
    property string position: "bottom"

    // Screen names to show the dock on (see `niri msg outputs`). Empty = all screens.
    property var screens: []

    // Desktop entry IDs (the .desktop filename without ".desktop"), in dock order.
    property var pinnedApps: ["zen", "Alacritty", "org.gnome.Nautilus", "dev.zed.Zed", "slack"]

    // Also show apps that are open but not pinned.
    property bool showRunning: true

    property int iconSize: 42
    property int spacing: 12      // gap between icons
    property int padding: 12      // gap between icons and the dock's edge
    property int margin: 16       // gap between the dock and the screen edge
    property int radius: 20
    property real opacity: 0.65  // background opacity, 0–1

    property real hoverScale: 1.15
    property bool bounceOnHover: true

    // Hide until the pointer touches the screen edge.
    property bool autoHide: true
    property int hideDelay: 600  // ms after the pointer leaves

    // Reserve screen space so windows don't go under the dock (ignored when autoHide is on).
    property bool reserveSpace: true
}
