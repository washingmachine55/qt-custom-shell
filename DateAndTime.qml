import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs

ShellRoot {
	Variants {
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
				width: content.implicitWidth
				height: content.implicitHeight

				// --- PHYSICS & CONFIGURATION PROPERTIES ---
				property real vx: 0.0          // Current X velocity
				property real vy: 0.0          // Current Y velocity
				property real friction: 0.98   // Resistance factor (0.90 = high resistance, 0.99 = low friction glide)
				property real bounce: 0.1      // Energy retention on wall bounce (0.0 = stops dead, 1.0 = perfect bounce)

				// Keep track of the last known position to calculate velocity chunks
				property int lastMouseX: 0
				property int lastMouseY: 0

				Behavior on x {
					// Only use the smooth behavior during the 10-minute random jump timer
					enabled: !dragArea.pressed && !physicsTimer.running
					NumberAnimation {
						duration: 1000
						easing.type: Easing.InOutCubic
					}
				}
				Behavior on y {
					enabled: !dragArea.pressed && !physicsTimer.running
					NumberAnimation {
						duration: 1000
						easing.type: Easing.InOutCubic
					}
				}

				ColumnLayout {
					id: content
					spacing: -20

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

				MouseArea {
					id: dragArea
					anchors.fill: parent

					// 1. Keeps the standard cursor type so it doesn't reveal it's clickable
					cursorShape: Qt.ArrowCursor

					onPressed: mouse => {
						physicsTimer.stop();
						dateAndTime.vx = 0;
						dateAndTime.vy = 0;
						dateAndTime.lastMouseX = mouse.x;
						dateAndTime.lastMouseY = mouse.y;
					}

					onPositionChanged: mouse => {
						if (pressed) {
							// Calculate relative pixel changes frame-by-frame
							let deltaX = mouse.x - dateAndTime.lastMouseX;
							let deltaY = mouse.y - dateAndTime.lastMouseY;

							// Instantly push the item across coordinates
							let nextX = dateAndTime.x + deltaX;
							let nextY = dateAndTime.y + deltaY;

							// Bind constraints while dragging
							dateAndTime.x = Math.max(0, Math.min(nextX, root.implicitWidth - dateAndTime.width));
							dateAndTime.y = Math.max(0, Math.min(nextY, root.implicitHeight - dateAndTime.height));

							// Accumulate current tracking velocity vector
							dateAndTime.vx = deltaX;
							dateAndTime.vy = deltaY;
						}
					}

					onReleased: {
						// 2. Kick off physics calculations loop if velocity thresholds are met
						if (Math.abs(dateAndTime.vx) > 0.5 || Math.abs(dateAndTime.vy) > 0.5) {
							physicsTimer.start();
						}
					}
				}

				// 3. Custom Physics engine tracking frame updates (60fps loop)
				Timer {
					id: physicsTimer
					interval: 16 // roughly 60 fps
					repeat: true
					running: false
					onTriggered: {
						// Apply movement vector
						let newX = dateAndTime.x + dateAndTime.vx;
						let newY = dateAndTime.y + dateAndTime.vy;

						let minX = 0;
						let maxX = root.implicitWidth - dateAndTime.width;
						let minY = 0;
						let maxY = root.implicitHeight - dateAndTime.height;

						// X boundary tracking and wall reflection bounce mechanics
						if (newX < minX) {
							newX = minX;
							dateAndTime.vx = -dateAndTime.vx * dateAndTime.bounce;
						} else if (newX > maxX) {
							newX = maxX;
							dateAndTime.vx = -dateAndTime.vx * dateAndTime.bounce;
						}

						// Y boundary tracking and wall reflection bounce mechanics
						if (newY < minY) {
							newY = minY;
							dateAndTime.vy = -dateAndTime.vy * dateAndTime.bounce;
						} else if (newY > maxY) {
							newY = maxY;
							dateAndTime.vy = -dateAndTime.vy * dateAndTime.bounce;
						}

						// Apply updates to position coordinates
						dateAndTime.x = newX;
						dateAndTime.y = newY;

						// Apply linear air resistance friction loss
						dateAndTime.vx *= dateAndTime.friction;
						dateAndTime.vy *= dateAndTime.friction;

						// Safely bring physics calculations to a dead halt when slow enough
						if (Math.abs(dateAndTime.vx) < 0.1 && Math.abs(dateAndTime.vy) < 0.1) {
							dateAndTime.vx = 0;
							dateAndTime.vy = 0;
							physicsTimer.stop();
						}
					}
				}

				Timer {
					interval: 600000 // 10 minutes in milliseconds
					repeat: true
					running: true
					triggeredOnStart: true
					onTriggered: {
						// Only jump automatically if not interacting or physics rolling
						if (!dragArea.pressed && !physicsTimer.running) {
							dateAndTime.x = Math.floor(Math.random() * (Math.floor(root.implicitWidth / 2) - Math.ceil(50) + 1)) + Math.ceil(50);
							dateAndTime.y = Math.floor(Math.random() * (Math.floor(root.implicitHeight / 2) - Math.ceil(50) + 1)) + Math.ceil(50);
						}
					}
				}
			}
		}
	}
}
