pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Wayland
import qs

Variants {
    model: Quickshell.screens.filter(s => DockSettings.screens.length === 0 || DockSettings.screens.includes(s.name))

    PanelWindow {
        id: win

        required property var modelData
        screen: modelData

        readonly property string edge: DockSettings.position
        readonly property bool vertical: edge === "left" || edge === "right"
        readonly property int thickness: DockSettings.iconSize + DockSettings.padding * 2
        // Room for hover scale and bounce so icons aren't clipped.
        readonly property int headroom: Math.ceil(DockSettings.iconSize * (DockSettings.hoverScale - 1) + DockSettings.iconSize * 0.3)

        property bool hidden: DockSettings.autoHide

        readonly property var apps: {
            DesktopEntries.applications.values;
            const list = [];
            const byKey = {};
            const keyFor = (entry, appId) => String(entry ? entry.id : appId).toLowerCase();

            for (const id of DockSettings.pinnedApps) {
                const entry = DesktopEntries.byId(id) ?? DesktopEntries.heuristicLookup(id);
                const item = { key: keyFor(entry, id), appId: id, entry: entry, pinned: true, toplevels: [] };
                list.push(item);
                byKey[item.key] = item;
            }

            for (const t of ToplevelManager.toplevels.values) {
                const entry = DesktopEntries.heuristicLookup(t.appId);
                const key = keyFor(entry, t.appId);
                let item = byKey[key];
                if (!item) {
                    if (!DockSettings.showRunning)
                        continue;
                    item = { key: key, appId: t.appId, entry: entry, pinned: false, toplevels: [] };
                    list.push(item);
                    byKey[key] = item;
                }
                item.toplevels.push(t);
            }
            return list;
        }

        color: "transparent"
        exclusiveZone: DockSettings.reserveSpace && !DockSettings.autoHide ? thickness + DockSettings.margin : 0
        WlrLayershell.namespace: "dock"
        WlrLayershell.layer: WlrLayer.Top

        // Anchoring to one edge only makes the compositor center the window along it.
        anchors {
            bottom: win.edge === "bottom"
            top: win.edge === "top"
            left: win.edge === "left"
            right: win.edge === "right"
        }

        implicitWidth: vertical ? thickness + DockSettings.margin + headroom : body.width + headroom * 2
        implicitHeight: vertical ? body.height + headroom * 2 : thickness + DockSettings.margin + headroom

        mask: Region { item: win.hidden ? sensor : body }

        function reveal() {
            hideTimer.stop();
            hidden = false;
        }

        function scheduleHide() {
            if (DockSettings.autoHide && !bodyHover.hovered)
                hideTimer.restart();
        }

        Timer {
            id: hideTimer
            interval: DockSettings.hideDelay
            onTriggered: win.hidden = DockSettings.autoHide && !bodyHover.hovered
        }

        Connections {
            target: DockSettings
            function onAutoHideChanged() {
                win.hidden = DockSettings.autoHide;
            }
        }

        Rectangle {
            id: body

            readonly property real hideOffset: win.hidden ? win.thickness + DockSettings.margin + 4 : 0

            width: win.vertical ? win.thickness : grid.implicitWidth + DockSettings.padding * 2
            height: win.vertical ? grid.implicitHeight + DockSettings.padding * 2 : win.thickness
            radius: DockSettings.radius
            color: Qt.alpha(Colors.md3.surface_container, DockSettings.opacity)
            border.width: 1
            border.color: Qt.alpha(Colors.md3.outline_variant, 0.5)

            x: win.vertical ? (win.edge === "left" ? DockSettings.margin - hideOffset : win.width - width - DockSettings.margin + hideOffset) : (win.width - width) / 2
            y: win.vertical ? (win.height - height) / 2 : (win.edge === "top" ? DockSettings.margin - hideOffset : win.height - height - DockSettings.margin + hideOffset)

            Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
            Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

            HoverHandler {
                id: bodyHover
                onHoveredChanged: hovered ? win.reveal() : win.scheduleHide()
            }

            Grid {
                id: grid
                anchors.centerIn: parent
                columns: win.vertical ? 1 : Math.max(1, win.apps.length)
                spacing: DockSettings.spacing

                Repeater {
                    model: win.apps

                    DockItem {
                        required property var modelData
                        app: modelData
                        edge: win.edge
                    }
                }
            }
        }

        // Thin strip on the screen edge that reveals the hidden dock.
        Item {
            id: sensor
            width: win.vertical ? 2 : body.width
            height: win.vertical ? body.height : 2
            x: win.vertical ? (win.edge === "left" ? 0 : win.width - width) : body.x
            y: win.vertical ? body.y : (win.edge === "top" ? 0 : win.height - height)

            HoverHandler {
                onHoveredChanged: hovered ? win.reveal() : win.scheduleHide()
            }
        }
    }
}
