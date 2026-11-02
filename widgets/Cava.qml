pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Io
import qs

// Audio visualizer bars from cava. All options can be set where it's placed in Widgets.qml.
Item {
	id: root

	// ── Position ──
	// "top-left", "top", "top-right", "left", "center", "right", "bottom-left", "bottom", "bottom-right"
	property string anchor: "bottom"
	property int offsetX: 0 // gap from the anchored left/right edge, or shift when centered
	property int offsetY: 0 // gap from the anchored top/bottom edge, or shift when centered
	property bool fillWidth: false // stretch across the screen (minus offsetX on each side); bar width is then computed

	// ── Bars ──
	property int bars: 24
	property int barWidth: 8 // ignored when fillWidth is on
	property int barSpacing: 4
	property int barHeight: 120 // tallest a bar can get
	property int minBarHeight: 2
	property bool roundBars: true
	property string direction: "up" // "up", "down" or "center" (grow both ways)

	// ── Colors ──
	// "single":   every bar uses color
	// "gradient": left-to-right blend from gradientStart to gradientEnd
	// "vertical": each bar blends from gradientStart (base) to gradientEnd (tip)
	// "level":    quiet bars use gradientStart, loud bars gradientEnd
	// "palette":  bars cycle through the paletteColors list
	property string colorMode: "single"
	property color color: Colors.md3.primary
	property color gradientStart: Colors.md3.primary
	property color gradientEnd: Colors.md3.tertiary
	property var paletteColors: [Colors.md3.primary, Colors.md3.secondary, Colors.md3.tertiary]
	property real barOpacity: 0.6

	// ── Behavior ──
	property int framerate: 60
	property int smoothing: 0 // ms of easing between frames; 0 = off
	property bool hideWhenSilent: false // fade out when nothing is playing
	property int silenceDelay: 2000 // ms of silence before hiding
	property bool stereo: false // left channel on the left half, right on the right
	property int noiseReduction: 77 // cava's smoothing, 0–100; higher is smoother but slower

	property var levels: [] // 0–1 per bar
	// Start cava only after Widgets.qml has applied its settings, or it launches with the defaults.
	property bool ready: false
	Component.onCompleted: ready = true
	readonly property real actualBarWidth: fillWidth ? (width - (bars - 1) * barSpacing) / bars : barWidth
	readonly property bool silent: levels.every(l => l === 0)

	function mix(a: color, b: color, t: real): color {
		return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, a.a + (b.a - a.a) * t);
	}

	function colorFor(index: int, level: real): color {
		switch (colorMode) {
		case "gradient":
			return mix(gradientStart, gradientEnd, bars > 1 ? index / (bars - 1) : 0);
		case "level":
			return mix(gradientStart, gradientEnd, level);
		case "palette":
			return paletteColors.length ? paletteColors[index % paletteColors.length] : color;
		default:
			return color;
		}
	}

	width: fillWidth ? parent.width - offsetX * 2 : bars * barWidth + (bars - 1) * barSpacing
	height: barHeight

	x: fillWidth ? offsetX : anchor.includes("left") ? offsetX : anchor.includes("right") ? parent.width - width - offsetX : (parent.width - width) / 2 + offsetX
	y: anchor.startsWith("top") ? offsetY : anchor.startsWith("bottom") ? parent.height - height - offsetY : (parent.height - height) / 2 + offsetY

	opacity: hideWhenSilent && silenceTimer.elapsed ? 0 : 1
	Behavior on opacity {
		NumberAnimation {
			duration: 400
		}
	}

	Timer {
		id: silenceTimer
		property bool elapsed: false
		interval: root.silenceDelay
		running: root.hideWhenSilent && root.silent
		onTriggered: elapsed = true
		onRunningChanged: if (!running)
			elapsed = false
	}

	Process {
		running: root.ready && root.visible
		// Raw ascii mode prints one "12;34;...;" line per frame, each value 0–100.
		command: ["sh", "-c", `conf="\${XDG_RUNTIME_DIR:-/tmp}/qs-cava-${root.bars}-${root.framerate}-${root.stereo}-${root.noiseReduction}.conf"
printf '[general]\\nbars = ${root.bars}\\nframerate = ${root.framerate}\\n[output]\\nmethod = raw\\nraw_target = /dev/stdout\\ndata_format = ascii\\nascii_max_range = 100\\nbar_delimiter = 59\\nchannels = ${root.stereo ? "stereo" : "mono"}\\n[smoothing]\\nnoise_reduction = ${root.noiseReduction}\\n' > "$conf"
exec cava -p "$conf"`]
		stdout: SplitParser {
			onRead: data => root.levels = data.split(";").filter(v => v !== "").map(v => Number(v) / 100)
		}
	}

	Row {
		anchors.fill: parent
		spacing: root.barSpacing
		opacity: root.barOpacity

		Repeater {
			model: root.bars

			Rectangle {
				required property int index
				readonly property real level: root.levels[index] ?? 0

				width: root.actualBarWidth
				height: Math.max(root.minBarHeight, root.height * level)
				y: root.direction === "down" ? 0 : root.direction === "center" ? (root.height - height) / 2 : root.height - height
				radius: root.roundBars ? width / 2 : 0
				color: root.colorFor(index, level)

				// Rectangle gradients run top to bottom, so flip the stops when bars grow upward.
				gradient: root.colorMode === "vertical" ? verticalGradient : null
				Gradient {
					id: verticalGradient
					GradientStop {
						position: 0
						color: root.direction === "down" ? root.gradientStart : root.gradientEnd
					}
					GradientStop {
						position: 1
						color: root.direction === "down" ? root.gradientEnd : root.gradientStart
					}
				}

				Behavior on height {
					enabled: root.smoothing > 0
					NumberAnimation {
						duration: root.smoothing
					}
				}
			}
		}
	}
}
