import QtQuick
import Quickshell
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
		WlrLayershell.layer: WlrLayer.Bottom

		// Only the lock takes clicks; everything else passes through to the desktop.
		mask: Region {
			item: lock
		}

		LockToggle {
			id: lock
			x: win.width - width - 80
			y: 80
		}

		TaskTimer {
			visible: ShellState.isWidgetsActive
			x: (win.width - width) / 2
			y: 9
		}
	}
}
