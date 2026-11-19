import QtQuick

Item {
	id: root
	property string textToShow: ""
	property int widgetWidth: 800
	property int fontSize: 22
	property string fontFamily: "zalando sans expanded"
	property int fontWeight: 500
	property real fontLetterSpacing: -19.5
	property int maxDuration: 10000
	property int minDuration: 150

	width: textColumn.width
	height: textColumn.height

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

								TextMetrics {
									id: glyphMetrics
									font: letterText.font
									text: modelData
								}

								Text {
									id: letterText
									text: modelData
									font.pointSize: root.fontSize
									color: Qt.alpha(Colors.md3.primary, letterContainer.transparency)
									font.family: root.fontFamily
									font.weight: root.fontWeight
									font.letterSpacing: root.fontLetterSpacing
									// renderType: Text.NativeRendering

									scale: letterContainer.isHovered ? 1.005 : 1.0
									transform: Translate {
										y: letterContainer.isHovered ? -40 : 0

										Behavior on y {
											NumberAnimation {
												duration: letterContainer.isHovered ? root.minDuration : root.maxDuration
												easing.type: letterContainer.isHovered ? Easing.OutBack : Easing.OutCubic
											}
										}
									}

									Behavior on scale {
										NumberAnimation {
											duration: letterContainer.isHovered ? root.minDuration : root.maxDuration
											easing.type: letterContainer.isHovered ? Easing.OutBack : Easing.OutCubic
										}
									}

									Behavior on color {
										ColorAnimation {
											duration: letterContainer.isHovered ? root.maxDuration : root.minDuration
										}
									}
								}

								// Tight hitbox matching only the visible glyph ink
								Item {
									id: tightHitbox
									x: glyphMetrics.tightBoundingRect.x
									// Align tight rect vertically with the centered Text element
									y: (letterContainer.height - letterText.height) / 2 + letterText.baselineOffset + glyphMetrics.tightBoundingRect.y
									width: Math.max(1, glyphMetrics.tightBoundingRect.width)
									height: Math.max(1, glyphMetrics.tightBoundingRect.height)

									HoverHandler {
										id: hoverHandler
										margin: 0 // No extra padding outside the glyph ink
									}
								}
							}
						}
					}
				}
			}
		}
	}
}
