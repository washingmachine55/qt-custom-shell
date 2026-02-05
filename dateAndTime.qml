import Quickshell 
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Material
import Quickshell.Wayland
import './Theme.qml'

ShellRoot {
    Variants {
		// Create the panel once on each monitor.
		model: Quickshell.screens

        PanelWindow {
            id: dateAndTime
            focusable: false
            visible: true
            color: "transparent"
            implicitHeight:1080
            implicitWidth: 1920
            aboveWindows: false
            Material.theme: Material.Dark
            WlrLayershell.layer: WlrLayer.Bottom
            mask: Region {}

            property var modelData
			screen: modelData

            ColumnLayout {
                id: content
                spacing: -20
                // x: Math.floor(Math.random() * (Math.floor(max)- Math.ceil(min) + 1)) + Math.ceil(min);
                x: Math.floor(Math.random() * (Math.floor(1580)- Math.ceil(50) + 1)) + Math.ceil(50);
                y: Math.floor(Math.random() * (Math.floor(850)- Math.ceil(50) + 1)) + Math.ceil(50);

                Behavior on x {
                    NumberAnimation {
                        duration: 1000    // 1 second
                        easing.type: Easing.InOutCubic
                    }
                }
                Behavior on y {
                    NumberAnimation {
                        duration: 1000
                        easing.type: Easing.InOutCubic
                    }
                }
                SystemClock {
                    id: clock
                    precision: SystemClock.Seconds
                    
                }
                Text {
                    id: clocktime
                    text: Qt.formatDateTime(clock.date, "hh:mm ")
                    font.pixelSize: 120
                    font.family: "zalando sans expanded"
                    font.weight: 990
                    font.letterSpacing: -7
                    font.italic: true
                    // color: '#000000'
                    color: Theme.accentColor
                    transformOrigin: Item.Center
                    renderType: Text.NativeRendering
                    smooth: true
                }
                Text {
                    id: clockdate
                    // text: Qt.formatDateTime(clock.date, "  ddd, dd/MM")
                    text: Qt.formatDateTime(clock.date, "  ddd, MMM dd")
                    font.pixelSize: 30
                    font.family: "zalando sans expanded"
                    font.weight: 500
                    font.letterSpacing: -1
                    color: Theme.accentColor
                    transformOrigin: Item.Center
                    renderType: Text.NativeRendering
                    smooth: true
                    // layer.enabled: true
                    // layer.samples: 4
                    // layer.smooth: true
                }
                Timer {
                    interval: 600000 // 10 minutes in milliseconds
                    // interval: 30000 // 1 minute in milliseconds
                    repeat: true
                    running: true
                    triggeredOnStart: true
                    onTriggered: {
                        // clocktime.text = Qt.formatTime(new Date(), "hh:mm:ss ");
                        content.x = Math.floor(Math.random() * (Math.floor(1580)- Math.ceil(50) + 1)) + Math.ceil(50);
                        content.y = Math.floor(Math.random() * (Math.floor(850)- Math.ceil(50) + 1)) + Math.ceil(50);
                    }
                }
            }
        }
    }
}
