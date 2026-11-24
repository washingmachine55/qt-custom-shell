import QtQuick
import Quickshell.Io
import qs

// Pill showing the running task total from scripts/taskTimer.sh.
Rectangle {
	id: root

	property string fontFamily: "JetBrainsMono Nerd Font"
	property int refreshInterval: 1000 // ms

	// Script prints "Task timer: 5h 13m 14s"; show the label and value separately.
	property string output: ""
	readonly property string label: output.includes(":") ? output.split(":")[0].trim() : "No timer is\ncurrently running"
	readonly property string value: output.includes(":") ? output.slice(output.indexOf(":") + 1).trim() : output
	readonly property string scriptUrl: Qt.resolvedUrl("../scripts/taskTimer.sh")

	width: root.value != "null" ? timerDetails.implicitWidth + 100 : ((row.anchors.leftMargin * 2) + icon.width)
	height: 75
	radius: height / 2
	color: Qt.alpha(Colors.md3.surface_container, Colors.transparency)
	border.color: Colors.md3.outline_variant
	border.width: 1

	Behavior on width {
		NumberAnimation {
			duration: 1000
			easing.type: Easing.OutCubic
		}
	}

	Process {
		id: proc
		command: [root.scriptUrl]
		stdout: SplitParser {
			onRead: data => root.output = data.trim()
		}
	}

	Timer {
		interval: root.refreshInterval
		running: root.opacity > 0
		repeat: true
		triggeredOnStart: true
		onTriggered: proc.running = true
	}

	Row {
		id: row
		anchors.verticalCenter: parent.verticalCenter
		anchors.left: parent.left
		anchors.leftMargin: 14
		spacing: 12

		Rectangle {
			id: icon
			anchors.verticalCenter: parent.verticalCenter
			width: 47
			height: 47
			radius: width / 2
			color: Colors.md3.primary_container

			Text {
				anchors.centerIn: parent
				text: root.value != "null" ? "\u{F13AB}" : "\u{F13AC}"
				color: Colors.md3.on_primary_container
				font.family: root.fontFamily
				font.pixelSize: 24
			}
		}

		Column {
			id: timerDetails
			anchors.verticalCenter: parent.verticalCenter
			spacing: 2
			opacity: root.value != "null" ? 1 : 0
			Behavior on opacity {
				NumberAnimation {
					duration: 1000
					easing.type: Easing.Linear
				}
			}

			Text {
				text: root.label.toUpperCase()
				visible: root.label != "null" ? true : false
				// anchors.horizontalCenter: parent.right
				color: Colors.md3.on_surface_variant
				font.family: root.fontFamily
				font.pixelSize: 11
				font.weight: 600
				font.letterSpacing: 1.5
			}

			Text {
				// Dim the h/m/s units so the digits stand out.
				text: root.value.replace(/(\d+)([a-z]+)/g, `$1<font color="${Colors.md3.on_surface_variant}">$2</font>`)
				visible: root.value != "null" ? true : false
				textFormat: Text.StyledText
				// anchors.horizontalCenter: parent.right
				color: Colors.md3.on_surface
				font.family: root.fontFamily
				font.pixelSize: 24
				font.weight: 700
				font.features: {
					"tnum": 1
				}
			}
		}
	}
}
