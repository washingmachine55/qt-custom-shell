import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets

Item {
    id: dockRoot

    required property var config
    required property var niri

    property bool vertical: config.edge === "left" || config.edge === "right"
    property bool hovered: false
    property real magnification: 1.08

    function sameApp(a, b) {
        return String(a ?? "").toLowerCase() === String(b ?? "").toLowerCase()
    }

    function appKey(window) {
        return window && window.app_id !== undefined ? String(window.app_id) : ""
    }

    function buildApps() {
        const result = []

        for (const pinned of config.pinnedApps) {
            const matches = niri.windows.filter(w => sameApp(appKey(w), pinned.appId))
            result.push({
                name: pinned.name,
                appId: pinned.appId,
                desktopId: pinned.desktopId,
                icon: pinned.icon,
                customIcon: pinned.customIcon,
                runningWindows: matches,
                running: matches.length > 0,
                focused: matches.some(w => !!w.is_focused)
            })
        }

        // Add apps with windows that are not pinned.
        for (const window of niri.windows) {
            const id = appKey(window)
            if (!id)
                continue

            const alreadyAdded = result.some(app => sameApp(app.appId, id))
            if (alreadyAdded)
                continue

            const matches = niri.windows.filter(w => sameApp(appKey(w), id))
            result.push({
                name: id,
                appId: id,
                desktopId: "",
                icon: id,
                customIcon: "",
                runningWindows: matches,
                running: true,
                focused: matches.some(w => !!w.is_focused)
            })
        }

        return result
    }

    property var apps: buildApps()

    implicitWidth: vertical
        ? config.iconSize + config.padding * 2
        : Math.max(1, apps.length) * config.iconSize
          + Math.max(0, apps.length - 1) * config.iconSpacing
          + config.padding * 2

    implicitHeight: vertical
        ? Math.max(1, apps.length) * config.iconSize
          + Math.max(0, apps.length - 1) * config.iconSpacing
          + config.padding * 2
        : config.iconSize + config.padding * 2

    function activate(app) {
        const list = app.runningWindows || []
        if (list.length > 0) {
            let currentIndex = list.findIndex(w => !!w.is_focused)
            const nextIndex = (currentIndex + 1) % list.length
            niri.focusWindow(list[nextIndex].id)
            return
        }

        if (app.desktopId && app.desktopId.length > 0) {
            Quickshell.execDetached(["gtk-launch", app.desktopId])
        } else {
            console.warn("macdock: no desktopId configured for", app.name)
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: 20
        color: "#df202127"
        border.color: "#42ffffff"
        border.width: 1
    }

    Row {
        anchors.centerIn: parent
        spacing: dockRoot.config.iconSpacing
        visible: !dockRoot.vertical

        Repeater {
            model: dockRoot.apps
            delegate: appDelegate
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: dockRoot.config.iconSpacing
        visible: dockRoot.vertical

        Repeater {
            model: dockRoot.apps
            delegate: appDelegate
        }
    }

    Component {
        id: appDelegate

        Item {
            id: appItem

            required property var modelData
            property var app: modelData

            width: dockRoot.config.iconSize
            height: dockRoot.config.iconSize

            scale: pointer.containsMouse ? dockRoot.magnification : 1.0
            Behavior on scale {
                NumberAnimation {
                    duration: 130
                    easing.type: Easing.OutCubic
                }
            }

            IconImage {
                anchors.fill: parent
                source: appItem.app.customIcon && appItem.app.customIcon.length > 0
                    ? appItem.app.customIcon
                    : Quickshell.iconPath(appItem.app.icon, "application-x-executable")
                asynchronous: true
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: -5
                width: 5
                height: 5
                radius: 2.5
                visible: appItem.app.running
                color: appItem.app.focused ? "#ffffff" : "#aab9ca"
            }

            MouseArea {
                id: pointer
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                onEntered: dockRoot.hovered = true
                onExited: dockRoot.hovered = false
                onClicked: dockRoot.activate(appItem.app)
            }

            ToolTip.visible: pointer.containsMouse
            ToolTip.text: appItem.app.name
            ToolTip.delay: 500
        }
    }
}
