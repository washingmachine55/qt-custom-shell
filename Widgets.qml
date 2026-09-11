import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Controls.Material
import Quickshell.Wayland
// import QtQuick.Layouts
import './Theme.qml'

Variants {
    // Create the panel once on each monitor.
    model: Quickshell.screens
    PanelWindow {
        id: widgets
        focusable: true
        visible: true
        color: "transparent"
        implicitHeight: screen.height
        implicitWidth: screen.width
        aboveWindows: false
        Material.theme: Material.Dark
        WlrLayershell.layer: WlrLayer.Bottom
        mask: Region {}

        property var modelData
        screen: modelData

        property string timerValue: ""

        Process {
            id: cpuProc
            command: ["/home/devmed/qt-custom-shell/scripts/taskTimer.sh"]
            stdout: SplitParser {
                onRead: data => {
                    widgets.timerValue = data.trim();
                }
            }
        }

        Timer {
            interval: 1000
            running: true
            repeat: true
            triggeredOnStart: true
            onTriggered: {
                cpuProc.running = true;
            }
        }

        Item {
            property real margin: 5

            // Set the implicit size of the containing item to the size of
            // the contained item, plus the margin on each side.
            implicitWidth: widgets.implicitWidth + margin * 2
            implicitHeight: widgets.implicitHeight + margin * 2

            Rectangle {
                id: child

                // Set the size of the child item relative to the actual size
                // of the parent item. If the parent item is constrained
                // or stretched the child's position and size will be similarly
                // constrained.
                x: (widgets.implicitWidth / 2) - child.width + 175
                y: 9
                width: 350
                height: 75
                radius: 20.0
                border.color: Theme.accentColor
                border.width: 1

                // The child's implicit / desired size, which will be respected
                // by the container item as long as it is not constrained
                // or stretched.
                implicitWidth: 50
                implicitHeight: 50
                opacity: 0.5
                color: "black"
                Text {
                    anchors.centerIn: parent
                    text: widgets.timerValue
                    color: "#ffffff"
                    font.pixelSize: 18
                    // font.family: "zalando sans expanded"
                    font.family: "JetBrains Mono Nerd Font Mono"
                    font.weight: 700
                }
            }
        }
    }
}
