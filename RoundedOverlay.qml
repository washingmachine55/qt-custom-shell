import Quickshell
import QtQuick
import QtQuick.Controls.Material
import Quickshell.Wayland
import Qt5Compat.GraphicalEffects

Variants {
	// Create the panel once on each monitor.
	model: Quickshell.screens
	PanelWindow {
		id: roundedOverlay
		focusable: false
		visible: true
		color: "transparent"
		implicitHeight: screen.height
		implicitWidth: screen.width
		aboveWindows: true
		Material.theme: Material.Dark
		WlrLayershell.layer: WlrLayer.Top
		mask: Region {}

		property var modelData
		screen: modelData

		// top-left
		Image {
			id: topLeftCorn
			visible: false
			anchors.left: parent.left
			anchors.top: parent.top
			source: "icons/corner.png"
			width: 25
			height: 25
			smooth: true
		}

		ColorOverlay {
	        anchors.fill: topLeftCorn
	        source: topLeftCorn
	        color: Colors.md3.surface
			opacity: 0.75 // Change this to any desired color
	    }

		// top-right
		Image {
			id: topRightCorn
			visible: false
			anchors.right: parent.right
			anchors.top: parent.top
			source: "icons/corner.png"
			width: 25
			height: 25
			smooth: true
		}

		ColorOverlay {
	        anchors.fill: topRightCorn
	        source: topRightCorn
	        color: Colors.md3.surface
			opacity: 0.75 // Change this to any desired color
			rotation: 90
			transformOrigin: Item.Center
	    }

		// bottom-right
		Image {
			id: bottomRightCorn
			visible: false
			anchors.right: parent.right
			anchors.bottom: parent.bottom
			source: "icons/corner.png"
			width: 25
			height: 25
			smooth: true
			rotation: 180
			transformOrigin: Item.Center
		}

		ColorOverlay {
	        anchors.fill: bottomRightCorn
	        source: bottomRightCorn
	        color: Colors.md3.surface
			opacity: 0.75 // Change this to any desired color
			rotation: 180
			transformOrigin: Item.Center
	    }

		// bottom-left
		Image {
			id: bottomLeftCorn
			visible: false
			anchors.left: parent.left
			anchors.bottom: parent.bottom
			source: "icons/corner.png"
			width: 25
			height: 25
			smooth: true
		}

		ColorOverlay {
	        anchors.fill: bottomLeftCorn
	        source: bottomLeftCorn
	        color: Colors.md3.surface
			opacity: 0.75 // Change this to any desired color
			rotation: 270
			transformOrigin: Item.Center
	    }
	}
}
