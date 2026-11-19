import QtQuick

Item {
	id: root
	property string textToShow: ""
	property int widgetWidth: 800
	property int fontSize: 22
	property string fontFamily: "Poppins"
	property int fontWeight: 500
	property real fontLetterSpacing: -12.5

	// Automatically match the container height to the rendered text
	implicitWidth: widgetWidth
	implicitHeight: textColumn.height

	// Invisible Text element used solely to measure exact word widths in Poppins
	Text {
		id: textMetrics
		visible: false
		font.pointSize: root.fontSize
		font.family: root.fontFamily
		font.weight: root.fontWeight
		font.letterSpacing: root.fontLetterSpacing // Adjusted: -18.0 overlaps letters completely on single characters
		renderType: Text.NativeRendering
	}

	// Helper function to group words into lines that fit inside root.widgetWidth
	function buildLines(fullText, maxWidth) {
		if (!fullText)
			return [];

		var paragraphs = fullText.split("\n");
		var allLines = [];
		var wordGap = 12; // Space between words

		for (var p = 0; p < paragraphs.length; p++) {
			var words = paragraphs[p].split(" ");
			var currentLine = [];
			var currentLineWidth = 0;

			for (var i = 0; i < words.length; i++) {
				var word = words[i];
				if (word.length === 0)
					continue;
				textMetrics.text = word;
				var wordWidth = textMetrics.advance.width;

				if (currentLine.length === 0) {
					currentLine.push(word);
					currentLineWidth = wordWidth;
				} else if (currentLineWidth + wordGap + wordWidth <= maxWidth) {
					currentLine.push(word);
					currentLineWidth += wordGap + wordWidth;
				} else {
					allLines.push(currentLine);
					currentLine = [word];
					currentLineWidth = wordWidth;
				}
			}
			if (currentLine.length > 0) {
				allLines.push(currentLine);
			}
		}
		return allLines;
	}

	Column {
		id: textColumn
		anchors.centerIn: parent
		spacing: -44

		// 1. Line Repeater: Creates each centered line
		Repeater {
			model: root.buildLines(root.textToShow, root.widgetWidth)

			delegate: Row {
				id: lineRow
				anchors.horizontalCenter: parent.horizontalCenter // Centers every line!
				spacing: 32 // Horizontal space between words
				property var wordsInLine: modelData

				// 2. Word Repeater: Keeps letters of a word together
				Repeater {
					model: lineRow.wordsInLine

					delegate: Row {
						id: wordRow
						spacing: 0 // Letter spacing is controlled below
						property string currentWord: modelData

						// 3. Letter Repeater: Individual hoverable characters
						Repeater {
							model: wordRow.currentWord.split("")

							delegate: Item {
								id: letterContainer
								width: letterText.width
								height: letterText.height

								property bool isHovered: hoverHandler.hovered
								property real transparency: letterContainer.isHovered ? 0.95 : 0

								Text {
									id: letterText
									text: modelData
									font.pointSize: root.fontSize
									color: Qt.alpha(Colors.md3.primary, letterContainer.transparency)
									font.family: root.fontFamily
									font.weight: root.fontWeight
									font.letterSpacing: root.fontLetterSpacing
									// renderType: Text.NativeRendering

									y: letterContainer.isHovered ? -2 : 0
									scale: letterContainer.isHovered ? 1.05 : 1.0

									Behavior on y {
										NumberAnimation {
											duration: letterContainer.isHovered ? 50 : 12000
											easing.type: letterContainer.isHovered ? Easing.OutBack : Easing.OutCubic
										}
									}

									Behavior on scale {
										NumberAnimation {
											duration: letterContainer.isHovered ? 50 : 12000
											easing.type: letterContainer.isHovered ? Easing.OutBack : Easing.OutCubic
										}
									}

									Behavior on color {
										ColorAnimation {
											duration: letterContainer.isHovered ? 12000 : 50
										}
									}
								}

								HoverHandler {
									id: hoverHandler
									margin: 1
								}
							}
						}
					}
				}
			}
		}
	}
}
