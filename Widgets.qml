import Quickshell
import Quickshell.Widgets
import Quickshell.Io
import QtQuick
import QtQuick.Controls.Material
import QtQuick.Effects
import Quickshell.Wayland
// import QtQuick.Layouts

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
        mask: Region {
            item: testReckt
        }

        property var modelData
        screen: modelData

        property bool isWidgetsActive: true
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

        property bool isDarkScheme: false

        Process {
            running: true
            command: ["sh", "-c", "gsettings get org.gnome.desktop.interface color-scheme; exec gsettings monitor org.gnome.desktop.interface color-scheme"]
            stdout: SplitParser {
                onRead: data => widgets.isDarkScheme = data.includes("prefer-dark")
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

        Rectangle {
            id: testReckt
            property string lockClosed: "file://home/devmed/qt-custom-shell/icons/lock-keyhole.png"
            property string lockOpen: "file://home/devmed/qt-custom-shell/icons/lock-keyhole-open.png"
            signal clicked(var mouse)
            implicitHeight: 80
            implicitWidth: 80
            x: widgets.implicitWidth - 80 -80
            y: widgets.implicitHeight - widgets.implicitHeight + 80
            opacity: 0.75
            color: "transparent"
            IconImage {
                id: lockIcon
                asynchronous: true
                layer.enabled: widgets.isDarkScheme
                layer.effect: MultiEffect {
                    brightness: 1.0
                }
                source: ShellState.isWidgetsActive ? testReckt.lockOpen : testReckt.lockClosed
                transformOrigin: Item.Center
                height: 24
                width: 24
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
            }
            MouseArea {
                id: moduleArea2
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton

                onClicked: ShellState.isWidgetsActive = !ShellState.isWidgetsActive
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
                visible: ShellState.isWidgetsActive

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
