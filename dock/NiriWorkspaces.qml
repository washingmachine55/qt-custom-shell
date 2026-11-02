pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
	id: root

	// Output names whose active workspace has no windows.
	property var emptyOutputs: []

	function isEmpty(output: string): bool {
		return emptyOutputs.includes(output);
	}

	Process {
		id: events
		running: true
		command: ["niri", "msg", "-j", "event-stream"]
		stdout: SplitParser {
			onRead: refresh.restart()
		}
		onExited: reconnect.start()
	}

	Timer {
		id: reconnect
		interval: 2000
		onTriggered: events.running = true
	}

	// Events arrive in bursts (e.g. switching workspaces); query once after they settle.
	Timer {
		id: refresh
		interval: 50
		onTriggered: query.running = true
	}

	Process {
		id: query
		command: ["niri", "msg", "-j", "workspaces"]
		stdout: StdioCollector {
			onStreamFinished: {
				try {
					// niri only leaves active_window_id null when the workspace has no windows.
					root.emptyOutputs = JSON.parse(text).filter(w => w.is_active && w.active_window_id === null).map(w => w.output);
				} catch (e) {
					console.warn("NiriWorkspaces: could not parse niri workspaces:", e);
				}
			}
		}
	}
}
