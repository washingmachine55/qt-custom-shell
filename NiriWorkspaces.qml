pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
	id: root

	// Output names whose active workspace has no windows.
	property var emptyOutputs: []
	// Output name -> [width, height] of the active window on that output's active workspace.
	property var activeWindowSizes: ({})

	function isEmpty(output: string): bool {
		return emptyOutputs.includes(output);
	}

	// Fraction (0–1) of the output covered by its active window.
	function coverage(output: string, outputWidth: real, outputHeight: real): real {
		const size = activeWindowSizes[output];
		return size && outputWidth > 0 && outputHeight > 0 ? Math.min(1, size[0] * size[1] / (outputWidth * outputHeight)) : 0;
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
		// Prints the workspaces JSON on line 1 and the windows JSON on line 2.
		command: ["sh", "-c", "niri msg -j workspaces; niri msg -j windows"]
		stdout: StdioCollector {
			onStreamFinished: {
				try {
					const [workspacesJson, windowsJson] = text.trim().split("\n");
					const active = JSON.parse(workspacesJson).filter(w => w.is_active);
					const windows = JSON.parse(windowsJson);
					// niri only leaves active_window_id null when the workspace has no windows.
					root.emptyOutputs = active.filter(w => w.active_window_id === null).map(w => w.output);
					const sizes = {};
					for (const ws of active) {
						const win = windows.find(w => w.id === ws.active_window_id);
						if (win)
							sizes[ws.output] = win.layout.tile_size;
					}
					root.activeWindowSizes = sizes;
				} catch (e) {
					console.warn("NiriWorkspaces: could not parse niri output:", e);
				}
			}
		}
	}
}
