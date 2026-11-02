import QtQuick
import QtQuick.Effects
import Quickshell.Io
import Quickshell.Widgets
import qs

// Lock icon that shows/hides the other widgets. Drawn white on dark color schemes.
Item {
	id: root

	property bool darkScheme: false

	width: 80
	height: 80
	opacity: 0.75

	IconImage {
		anchors.centerIn: parent
		width: 24
		height: 24
		asynchronous: true
		source: Qt.resolvedUrl(ShellState.isWidgetsActive ? "../icons/lock-keyhole-open.png" : "../icons/lock-keyhole.png")
		layer.enabled: root.darkScheme
		layer.effect: MultiEffect {
			brightness: 1.0
		}
	}

	MouseArea {
		anchors.fill: parent
		acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
		onClicked: ShellState.isWidgetsActive = !ShellState.isWidgetsActive
	}

	Process {
		running: true
		command: ["sh", "-c", "gsettings get org.gnome.desktop.interface color-scheme; exec gsettings monitor org.gnome.desktop.interface color-scheme"]
		stdout: SplitParser {
			onRead: data => root.darkScheme = data.includes("prefer-dark")
		}
	}
}
