import QtQuick
import QtQuick.Layouts

Item {
	id: root
	property string textToShow: ""
	property int fontSize: 22
	property real transparency: 0.0

	ColumnLayout {
		id: content
		anchors.centerIn: parent

		Text {
			text: root.textToShow
			color: Qt.alpha(Colors.md3.tertiary, root.transparency)
			font.pointSize: root.fontSize
			font.family: "Poppins"
			font.weight: 700
			font.wordSpacing: 18.0
			font.letterSpacing: -13.0
			renderType: Text.NativeRendering

			scale: hoverHandler.hovered ? 1.1 : 1.0

			Behavior on scale {
				NumberAnimation {
					duration: 150
					easing.type: Easing.OutQuad
				}
			}

			HoverHandler {
				id: hoverHandler
				cursorShape: Qt.PointingHandCursor // Optional: changes cursor on hover
			}
		}
	}
}
