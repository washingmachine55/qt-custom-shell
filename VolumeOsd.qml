pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Wayland
import qs

Scope {
	id: volumeOsd

	// ── Config ──
	property string position: "top"     // screen edge: "top", "bottom", "left" or "right"
	property string stacking: "vertical"  // how the two pills stack: "vertical" or "horizontal"
	property string font: "Poppins"
	property int pillThickness: 60        // short side of a pill
	property int pillLength: 375          // long side; runs along the edge (vertical on left/right, horizontal on top/bottom)
	property int trackThickness: 12       // the bar inside the pill
	property int pillRadius: pillThickness / 2
	property int pillSpacing: 12          // gap between volume and brightness pills
	property int edgeMargin: 42           // gap from the screen edge
	property int hideDelay: 2500          // ms
	property int slideDuration: 550       // ms, pill slide in/out and space reflow
	property int iconSize: 24
	property int textSize: 14
	property int endPadding: 22           // inside the pill at both ends of its length (left/right on horizontal pills, top/bottom on vertical)
	property int sidePadding: 12          // inside the pill across its thickness
	property int contentSpacing: 14       // gap between icon, bar and text
	property real bgOpacity: Colors.transparency
	property color bgColor: Colors.md3.on_secondary_fixed
	property color borderColor: Colors.md3.outline_variant
	property color trackColor: Colors.md3.on_primary
	property color fillColor: Colors.md3.primary
	property color mutedFillColor: Colors.md3.outline
	property color textColor: Colors.md3.secondary_fixed
	property color iconColor: Colors.md3.primary

	readonly property bool horizontalPill: position === "top" || position === "bottom"
	readonly property bool stackHorizontal: stacking === "horizontal"
	readonly property int pillW: horizontalPill ? pillLength : pillThickness
	readonly property int pillH: horizontalPill ? pillThickness : pillLength

	property bool showVolume: false
	property bool showBrightness: false
	property real volumeValue: 0
	property bool volumeMuted: false
	property real brightnessValue: 0
	property real maxBrightness: 1
	property bool _brightnessReady: false

	// PipeWire tracking
	PwObjectTracker {
		objects: [Pipewire.defaultAudioSink]
	}

	Connections {
		target: Pipewire.defaultAudioSink?.audio ?? null

		function onVolumeChanged() {
			volumeOsd.volumeValue = Pipewire.defaultAudioSink.audio.volume;
			volumeOsd.showVolume = true;
			volumeHideTimer.restart();
		}

		function onMutedChanged() {
			volumeOsd.volumeMuted = Pipewire.defaultAudioSink.audio.muted;
			volumeOsd.showVolume = true;
			volumeHideTimer.restart();
		}
	}

	Timer {
		id: volumeHideTimer
		interval: volumeOsd.hideDelay
		onTriggered: volumeOsd.showVolume = false
	}

	// Brightness monitoring
	FileView {
		id: brightnessFile
		path: ""
		watchChanges: true
		onFileChanged: brightnessReadProc.running = true
	}

	Process {
		id: brightnessReadProc
		command: ["brightnessctl", "get"]
		running: false
		stdout: StdioCollector {
			onStreamFinished: {
				const val = parseInt(text.trim());
				if (!isNaN(val) && volumeOsd.maxBrightness > 0) {
					volumeOsd.brightnessValue = val / volumeOsd.maxBrightness;
					if (volumeOsd._brightnessReady) {
						volumeOsd.showBrightness = true;
						brightnessHideTimer.restart();
					}
					volumeOsd._brightnessReady = true;
				}
			}
		}
	}

	Process {
		id: backlightDiscovery
		command: ["sh", "-c", "p=$(ls -d /sys/class/backlight/*/brightness 2>/dev/null | head -1); [ -n \"$p\" ] && echo \"$p\" && cat \"${p%brightness}max_brightness\""]
		running: true
		stdout: StdioCollector {
			onStreamFinished: {
				const lines = text.trim().split("\n");
				if (lines.length >= 2) {
					const max = parseInt(lines[1]);
					if (!isNaN(max) && max > 0)
						volumeOsd.maxBrightness = max;
					brightnessFile.path = lines[0];
					brightnessReadProc.running = true;
				}
			}
		}
	}

	Timer {
		id: brightnessHideTimer
		interval: volumeOsd.hideDelay
		onTriggered: volumeOsd.showBrightness = false
	}

	Variants {
		model: Quickshell.screens

		PanelWindow {
			id: win
			required property var modelData
			screen: modelData

			// Always mapped (transparent, click-through) so show/hide animations run in-scene;
			// mapping the window on show made the first frames jump.
			visible: true
			focusable: false
			color: "transparent"

			WlrLayershell.layer: WlrLayer.Overlay
			WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
			WlrLayershell.namespace: "quickshell-osd"

			exclusionMode: ExclusionMode.Ignore
			mask: Region {}

			// Anchored to one edge only, so the compositor centers it along that edge.
			anchors {
				top: volumeOsd.position === "top"
				bottom: volumeOsd.position === "bottom"
				left: volumeOsd.position === "left"
				right: volumeOsd.position === "right"
			}

			// Fixed size (room for both pills) so the compositor doesn't re-center every frame.
			// Includes edgeMargin so pills slide past the screen edge instead of being cut off early.
			readonly property int contentW: volumeOsd.stackHorizontal ? (volumeOsd.pillW + volumeOsd.pillSpacing) * 2 : volumeOsd.pillW
			readonly property int contentH: volumeOsd.stackHorizontal ? volumeOsd.pillH : (volumeOsd.pillH + volumeOsd.pillSpacing) * 2
			implicitWidth: contentW + (volumeOsd.horizontalPill ? 0 : volumeOsd.edgeMargin)
			implicitHeight: contentH + (volumeOsd.horizontalPill ? volumeOsd.edgeMargin : 0)

			Grid {
				id: pills
				columns: volumeOsd.stackHorizontal ? 2 : 1

				// Hug the pinned edge, centered along it.
				x: volumeOsd.position === "left" ? volumeOsd.edgeMargin : volumeOsd.position === "right" ? win.width - width - volumeOsd.edgeMargin : (win.width - width) / 2
				y: volumeOsd.position === "top" ? volumeOsd.edgeMargin : volumeOsd.position === "bottom" ? win.height - height - volumeOsd.edgeMargin : (win.height - height) / 2

				Repeater {
					// A plain count keeps delegates alive; a rebuilt JS array would recreate them on every change.
					model: 2

					Item {
						id: slot
						required property int index
						readonly property bool isVolume: index === 0
						readonly property bool shown: isVolume ? volumeOsd.showVolume : volumeOsd.showBrightness
						readonly property real value: isVolume ? volumeOsd.volumeValue : volumeOsd.brightnessValue
						readonly property bool muted: isVolume && volumeOsd.volumeMuted
						readonly property string label: isVolume ? (muted ? "Volume: muted" : "Volume: " + Math.round(value * 100) + "%") : "Brightness: " + Math.round(value * 100) + "%"
						readonly property string icon: isVolume ? (muted || value <= 0 ? "󰖁" : value < 0.33 ? "󰕿" : value < 0.66 ? "󰖀" : "󰕾") : (value < 0.33 ? "󰃞" : value < 0.66 ? "󰃟" : "󰃠")

						// Size along the stacking axis animates to open/close space. Half the spacing on
						// each side, so two pills get one full gap and a single pill stays centered.
						width: volumeOsd.stackHorizontal ? (shown ? volumeOsd.pillW + volumeOsd.pillSpacing : 0) : volumeOsd.pillW
						height: volumeOsd.stackHorizontal ? volumeOsd.pillH : (shown ? volumeOsd.pillH + volumeOsd.pillSpacing : 0)
						Behavior on width {
							NumberAnimation {
								duration: volumeOsd.slideDuration
								easing.type: Easing.OutCubic
							}
						}
						Behavior on height {
							NumberAnimation {
								duration: volumeOsd.slideDuration
								easing.type: Easing.OutCubic
							}
						}

						Rectangle {
							id: pill
							width: volumeOsd.pillW
							height: volumeOsd.pillH
							x: (slot.width - width) / 2
							y: (slot.height - height) / 2

							// Slide toward the pinned edge when hidden.
							// Just far enough to clear the window on the edge side.
							property real slideOffset: slot.shown ? 0 : (volumeOsd.horizontalPill ? win.height : win.width)
							transform: Translate {
								x: volumeOsd.position === "right" ? pill.slideOffset : volumeOsd.position === "left" ? -pill.slideOffset : 0
								y: volumeOsd.position === "bottom" ? pill.slideOffset : volumeOsd.position === "top" ? -pill.slideOffset : 0
							}
							// Decelerate in, accelerate out, so both directions read as a slide.
							Behavior on slideOffset {
								NumberAnimation {
									duration: volumeOsd.slideDuration
									easing.type: slot.shown ? Easing.OutCubic : Easing.InCubic
								}
							}

							radius: volumeOsd.pillRadius
							color: Qt.alpha(volumeOsd.bgColor, volumeOsd.bgOpacity)
							border.color: volumeOsd.borderColor
							border.width: 1
							opacity: slot.shown ? 1 : 0
							Behavior on opacity {
								NumberAnimation {
									duration: volumeOsd.slideDuration
									easing.type: slot.shown ? Easing.OutQuad : Easing.InQuad
								}
							}

							Accessible.role: Accessible.ProgressBar
							Accessible.name: slot.label

							// Vertical pill: label, bar, icon top to bottom. Horizontal pill: icon, bar, label left to right.
							GridLayout {
								anchors.fill: parent
								anchors.leftMargin: volumeOsd.horizontalPill ? volumeOsd.endPadding : volumeOsd.sidePadding
								anchors.rightMargin: volumeOsd.horizontalPill ? volumeOsd.endPadding : volumeOsd.sidePadding
								anchors.topMargin: volumeOsd.horizontalPill ? volumeOsd.sidePadding : volumeOsd.endPadding
								anchors.bottomMargin: volumeOsd.horizontalPill ? volumeOsd.sidePadding : volumeOsd.endPadding
								columns: volumeOsd.horizontalPill ? 3 : 1
								rowSpacing: volumeOsd.contentSpacing
								columnSpacing: volumeOsd.contentSpacing

								Text {
									Layout.row: volumeOsd.horizontalPill ? 0 : 2
									Layout.column: 0
									Layout.alignment: Qt.AlignCenter
									text: slot.icon
									color: volumeOsd.iconColor
									font.pixelSize: volumeOsd.iconSize
									font.family: volumeOsd.font
								}

								Rectangle {
									Layout.row: volumeOsd.horizontalPill ? 0 : 1
									Layout.column: volumeOsd.horizontalPill ? 1 : 0
									Layout.alignment: Qt.AlignCenter
									Layout.fillWidth: volumeOsd.horizontalPill
									Layout.fillHeight: !volumeOsd.horizontalPill
									Layout.preferredWidth: volumeOsd.horizontalPill ? -1 : volumeOsd.trackThickness
									Layout.preferredHeight: volumeOsd.horizontalPill ? volumeOsd.trackThickness : -1
									radius: volumeOsd.trackThickness / 2
									color: volumeOsd.trackColor
									clip: true

									Rectangle {
										readonly property real level: Math.max(0, Math.min(1, slot.muted ? 0 : slot.value))
										// Fills from the left on horizontal pills, from the bottom on vertical ones.
										width: volumeOsd.horizontalPill ? parent.width * level : parent.width
										height: volumeOsd.horizontalPill ? parent.height : parent.height * level
										y: parent.height - height
										radius: parent.radius
										color: slot.muted ? volumeOsd.mutedFillColor : volumeOsd.fillColor

										Behavior on width {
											NumberAnimation {
												duration: 100
												easing.type: Easing.OutCubic
											}
										}
										Behavior on height {
											NumberAnimation {
												duration: 100
												easing.type: Easing.OutCubic
											}
										}
									}
								}

								Text {
									Layout.row: 0
									Layout.column: volumeOsd.horizontalPill ? 2 : 0
									Layout.alignment: Qt.AlignCenter
									// Keeps the bar from jumping as the % text width changes.
									Layout.minimumWidth: volumeOsd.horizontalPill ? volumeOsd.textSize * 3 : -1
									horizontalAlignment: Text.AlignHCenter
									text: slot.muted ? "Mute" : Math.round(slot.value * 100) + "%"
									color: volumeOsd.textColor
									font.pixelSize: volumeOsd.textSize
									font.weight: 600
									font.family: volumeOsd.font
								}
							}
						}
					}
				}
			}
		}
	}
}
