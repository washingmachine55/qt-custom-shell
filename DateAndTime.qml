import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs

ShellRoot {
	Variants {
		// Create the panel once on each monitor.
		model: Quickshell.screens

		PanelWindow {
			id: root

			property var modelData
			screen: modelData

			focusable: true
			visible: true
			color: "transparent"
			implicitHeight: modelData.height
			implicitWidth: modelData.width
			aboveWindows: false
			Material.theme: Material.Dark
			WlrLayershell.layer: WlrLayer.Enum
			mask: Region {
				item: dateAndTime
			}

			Item {
				id: dateAndTime
				x: root.implicitWidth / 4
				y: root.implicitHeight / 4

				// 1. Force the container to match the actual rendered size of the layout text
				width: content.implicitWidth
				height: content.implicitHeight

				// 2. Control animations dynamically so they don't break manual dragging
				Behavior on x {
					// enabled: !dragArea.drag.active // Disable animation while dragging
					NumberAnimation {
						duration: 1000
						easing.type: Easing.InOutCubic
					}
				}
				Behavior on y {
					// enabled: !dragArea.drag.active // Disable animation while dragging
					NumberAnimation {
						duration: 1000
						easing.type: Easing.InOutCubic
					}
				}

				ColumnLayout {
					id: content
					spacing: -20
					// Do not fill parent; let the layout size naturally based on the text sizes

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
						color: Colors.md3.inverse_primary
						opacity: 0.95
						transformOrigin: Item.Center
						renderType: Text.NativeRendering
						smooth: true
					}
					Text {
						id: clockdate
						text: Qt.formatDateTime(clock.date, "  ddd, MMM dd")
						font.pixelSize: 30
						font.family: "zalando sans expanded"
						font.weight: 500
						font.letterSpacing: -1
						color: Colors.md3.primary_fixed_dim
						opacity: 0.85
						transformOrigin: Item.Center
						renderType: Text.NativeRendering
						smooth: true
					}
				}

				// 3. The MouseArea now has a real width/height to capture click events
				MouseArea {
					id: dragArea
					anchors.fill: parent
					cursorShape: Qt.SizeAllCursor
					drag.target: dateAndTime

					drag.minimumX: 0
					drag.maximumX: root.implicitWidth - dateAndTime.width
					drag.minimumY: 0
					drag.maximumY: root.implicitHeight - dateAndTime.height
				}

				Timer {
					// interval: 600000 // 10 minutes in milliseconds
					interval: 10000 // 10 minutes in milliseconds
					repeat: true
					running: true
					triggeredOnStart: true
					onTriggered: {
						// Only snap positions if the user isn't currently dragging it
						if (!dragArea.drag.active) {
							dateAndTime.x = Math.floor(Math.random() * (Math.floor(root.implicitWidth / 2) - Math.ceil(50) + 1)) + Math.ceil(50);
							dateAndTime.y = Math.floor(Math.random() * (Math.floor(root.implicitHeight / 2) - Math.ceil(50) + 1)) + Math.ceil(50);
						}
					}
				}
			}
		}
	}
}
