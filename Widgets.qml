import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs
import qs.widgets

// Desktop widgets, created on every screen. Add, remove or position widgets here;
// each widget lives in widgets/.
Variants {
	model: Quickshell.screens

	PanelWindow {
		id: win

		required property var modelData
		screen: modelData

		implicitWidth: modelData.width
		implicitHeight: modelData.height
		color: "transparent"
		focusable: true
		aboveWindows: false
		WlrLayershell.layer: WlrLayer.Background

		// Only the lock takes clicks; everything else passes through to the desktop.
		mask: Region {
			item: inputContainer
		}

		Item {
			id: inputContainer
			anchors.fill: parent

			LockToggle {
				id: lock
				x: win.width - width - 10
				y: 10
			}

			Calandar {
				id: calandarModule
				opacity: ShellState.isWidgetsActive ? 1 : 0

				Behavior on opacity {
					NumberAnimation {
						duration: 1000
						easing.type: Easing.OutCubic
					}
				}
			}

			NorthStar {
				id: northStar
				opacity: ShellState.isWidgetsActive ? 1 : 0
				fontSize: 394
				width: parent.width
				widgetWidth: win.modelData.width / 2
				y: (win.modelData.height - height) + 100

				textToShow: quoteCollector.text.trim()

				Behavior on opacity {
					NumberAnimation {
						duration: 1000
						easing.type: Easing.OutCubic
					}
				}
			}
		}

		Process {
			id: quoteProcess
			command: [Qt.resolvedUrl("./scripts/northStarText.sh")]
			running: ShellState.isWidgetsActive
			stdout: StdioCollector {
				id: quoteCollector
			}
		}

		TaskTimer {
			opacity: ShellState.isWidgetsActive ? 1 : 0
			x: (win.width - width) / 2
			y: 8

			Behavior on opacity {
				NumberAnimation {
					duration: 1000
					easing.type: Easing.OutCubic
				}
			}
		}

		Cava {
			visible: ShellState.isWidgetsActive
			screenName: win.modelData.name
			// screens: ["eDP-1"] // e.g. ["HDMI-A-1"]; empty = all screens
			screens: [] // e.g. ["HDMI-A-1"]; empty = all screens
			z: -1 // behind the other widgets; raise it to bring it forward

			// Position: anchor to a screen edge/corner, offsets are gaps from it.
			anchor: "center" // top-left, top, top-right, left, center, right, bottom-left, bottom, bottom-right
			// offsetX: 250
			// offsetY: 250
			fillWidth: true // stretch across the screen

			bars: 46
			barWidth: 14
			barSpacing: 24
			barHeight: 1080
			direction: "down" // up, down, center
			roundBars: true

			// Colors: single, gradient, vertical, level or palette (any Colors.md3.* works).
			colorMode: "vertical"
			// color: Colors.md3.on_secondary_container
			gradientStart: Colors.md3.primary
			gradientEnd: Qt.alpha(Colors.md3.scrim, 0)
			// paletteColors: [Colors.md3.primary, Colors.md3.scrim, Colors.md3.tertiary]
			barOpacity: 1

			framerate: 60 // lower (e.g. 30) to use less CPU
			pauseWhenCovered: true // stop while the focused window covers most of this screen
			coverThreshold: 0.8 // 0–1, fraction of the screen
			smoothing: 60 // ms
			// hideWhenSilent: true
			stereo: true
		}
	}
}
