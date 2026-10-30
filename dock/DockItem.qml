import QtQuick
import Quickshell
import Quickshell.Widgets
import qs

Item {
    id: root

    required property var app
    required property string edge

    readonly property bool vertical: edge === "left" || edge === "right"
    readonly property bool running: app.toplevels.length > 0
    readonly property var activeToplevel: app.toplevels.find(t => t.activated) ?? null
    // Direction pointing away from the screen edge, used for the bounce.
    readonly property point outward: edge === "bottom" ? Qt.point(0, -1) : edge === "top" ? Qt.point(0, 1) : edge === "left" ? Qt.point(1, 0) : Qt.point(-1, 0)

    implicitWidth: DockSettings.iconSize
    implicitHeight: DockSettings.iconSize

    function launch() {
        if (app.entry)
            app.entry.execute();
        else
            Quickshell.execDetached([app.appId]);
    }

    function activate() {
        if (!running) {
            launch();
            return;
        }
        // Clicking a dock on another output moves niri's focus there first, so the
        // app's window loses `activated`; fall back to the window we last switched to.
        const current = activeToplevel ?? (app.toplevels.includes(lastActivated) ? lastActivated : null);
        const i = current ? app.toplevels.indexOf(current) : -1;
        const next = app.toplevels[(i + 1) % app.toplevels.length];
        lastActivated = next;
        next.activate();
    }

    property var lastActivated: null

    IconImage {
        id: icon
        anchors.centerIn: parent
        implicitSize: DockSettings.iconSize
        source: Quickshell.iconPath(root.app.entry?.icon || root.app.appId, "application-x-executable")
        scale: mouse.containsMouse ? DockSettings.hoverScale : 1

        transform: Translate {
            id: bounce
        }

        Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
    }

    SequentialAnimation {
        id: bounceAnim
        readonly property real distance: DockSettings.iconSize * 0.1
        NumberAnimation { target: bounce; property: root.vertical ? "x" : "y"; to: (root.vertical ? root.outward.x : root.outward.y) * bounceAnim.distance; duration: 140; easing.type: Easing.OutQuad }
        NumberAnimation { target: bounce; property: root.vertical ? "x" : "y"; to: 0; duration: 260; easing.type: Easing.OutBounce }
    }

    // Running indicator: one dot per window (max 3), highlighted when focused.
    Grid {
        columns: root.vertical ? 1 : 3
        spacing: 3
        x: root.vertical ? (root.edge === "left" ? -6 : root.width + 2) : (root.width - width) / 2
        y: root.vertical ? (root.height - height) / 2 : (root.edge === "top" ? -6 : root.height + 2)

        Repeater {
            model: Math.min(root.app.toplevels.length, 3)

            Rectangle {
                width: 4
                height: 4
                radius: 2
                color: root.activeToplevel ? Colors.md3.primary : Colors.md3.on_surface_variant
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton

        onEntered: if (DockSettings.bounceOnHover) bounceAnim.restart()

        onClicked: event => {
            if (event.button === Qt.LeftButton)
                root.activate();
            else
                root.launch();
        }
    }
}
