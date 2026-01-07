import Quickshell 
import QtQuick
import QtQuick.Controls.Material
import Quickshell.Wayland

Variants {
	// Create the panel once on each monitor.
	model: Quickshell.screens
	PanelWindow {
		id: roundedOverlay
		focusable: false
		visible: true
		color: "transparent"
		implicitHeight:1080
		implicitWidth: 1920
		aboveWindows: true
		Material.theme: Material.Dark
		WlrLayershell.layer: WlrLayer.Top
		mask: Region {}

		property var modelData
		screen: modelData

		// top-left
		Image {
			anchors.left: parent.left
			anchors.top: parent.top
			source: "icons/corner.png"
			width: 25
			height: 25
			smooth: true
			rotation: 0
		}

		// top-right
		Image {
			anchors.right: parent.right
			anchors.top: parent.top
			source: "icons/corner.png"
			width: 25
			height: 25
			smooth: true
			rotation: 90
			transformOrigin: Item.Center
		}

		// bottom-right
		Image {
			anchors.right: parent.right
			anchors.bottom: parent.bottom
			source: "icons/corner.png"
			width: 25
			height: 25
			smooth: true
			rotation: 180
			transformOrigin: Item.Center
		}

		// bottom-left
		Image {
			anchors.left: parent.left
			anchors.bottom: parent.bottom
			source: "icons/corner.png"
			width: 25
			height: 25
			smooth: true
			rotation: 270
			transformOrigin: Item.Center
		}
	}
}