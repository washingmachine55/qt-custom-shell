import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: panelRoot

    required property var config
    required property var niri

    color: "transparent"
    exclusiveZone: 0

    property bool vertical: config.edge === "left" || config.edge === "right"
    property bool hidden: config.autoHide

    anchors {
        bottom: config.edge === "bottom"
        top: config.edge === "top"
        left: config.edge === "left"
        right: config.edge === "right"
    }

    // Keep the panel's layer-shell surface small and centered on its edge.
    implicitWidth: vertical ? 90 : Math.min(screen.width, 1200)
    implicitHeight: vertical ? Math.min(screen.height, 900) : 90

    function reveal() {
        hidden = false
        hideTimer.stop()
    }

    function scheduleHide() {
        if (config.autoHide && !dock.hovered)
            hideTimer.restart()
    }

    Timer {
        id: hideTimer
        interval: panelRoot.config.hideDelay
        repeat: false
        onTriggered: {
            if (!dock.hovered && panelRoot.config.autoHide)
                panelRoot.hidden = true
        }
    }

    Dock {
        id: dock
        config: panelRoot.config
        niri: panelRoot.niri

        anchors.centerIn: parent

        opacity: panelRoot.hidden ? 0.0 : 1.0
        Behavior on opacity {
            NumberAnimation { duration: 160 }
        }

        transform: Translate {
            x: panelRoot.hidden
                ? (panelRoot.config.edge === "left" ? -dock.width
                   : panelRoot.config.edge === "right" ? dock.width : 0)
                : 0
            y: panelRoot.hidden
                ? (panelRoot.config.edge === "top" ? -dock.height
                   : panelRoot.config.edge === "bottom" ? dock.height : 0)
                : 0

            Behavior on x { NumberAnimation { duration: 180 } }
            Behavior on y { NumberAnimation { duration: 180 } }
        }

        onHoveredChanged: {
            if (hovered)
                panelRoot.reveal()
            else
                panelRoot.scheduleHide()
        }
    }

    // Thin edge sensor: reveals the dock when the pointer reaches the chosen edge.
    MouseArea {
        z: 20
        hoverEnabled: true

        width: panelRoot.vertical ? 3 : panelRoot.width
        height: panelRoot.vertical ? panelRoot.height : 3

        x: panelRoot.config.edge === "right" ? panelRoot.width - width : 0
        y: panelRoot.config.edge === "bottom" ? panelRoot.height - height : 0

        onEntered: panelRoot.reveal()
        onExited: panelRoot.scheduleHide()
    }
}
