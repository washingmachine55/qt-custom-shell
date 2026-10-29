import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: niriRoot

    property var windows: []
    property bool connected: false
    property string lastError: ""

    function parseJson(line) {
        try {
            return JSON.parse(line)
        } catch (e) {
            console.warn("macdock: invalid niri JSON:", line)
            return null
        }
    }

    function unwrapEvent(value) {
        // Some niri IPC responses wrap tagged event data in "Ok".
        if (value && value.Ok !== undefined)
            return value.Ok
        return value
    }

    function windowId(w) {
        return w && w.id !== undefined ? String(w.id) : ""
    }

    function replaceWindow(w) {
        if (!w || w.id === undefined)
            return

        const id = windowId(w)
        const next = windows.slice()
        const i = next.findIndex(item => windowId(item) === id)
        if (i < 0)
            next.push(w)
        else
            next[i] = w

        windows = next
        connected = true
    }

    function removeWindow(id) {
        const key = String(id)
        windows = windows.filter(w => windowId(w) !== key)
    }

    function refreshWindows() {
        snapshot.running = true
    }

    function handleEventLine(line) {
        const parsed = parseJson(line)
        if (parsed === null)
            return

        const event = unwrapEvent(parsed)
        if (!event || typeof event !== "object")
            return

        // Initial state / windows-changed event.
        if (event.WindowsChanged !== undefined) {
            const payload = event.WindowsChanged
            const list = Array.isArray(payload) ? payload : payload.windows
            if (Array.isArray(list)) {
                windows = list
                connected = true
            } else {
                refreshWindows()
            }
            return
        }

        // New or changed window.
        if (event.WindowOpenedOrChanged !== undefined) {
            const payload = event.WindowOpenedOrChanged
            replaceWindow(payload.window !== undefined ? payload.window : payload)
            return
        }

        if (event.WindowClosed !== undefined) {
            const payload = event.WindowClosed
            const id = typeof payload === "object"
                ? (payload.id !== undefined ? payload.id : payload.window_id)
                : payload
            if (id !== undefined)
                removeWindow(id)
            else
                refreshWindows()
            return
        }

        // Focus event shapes vary; refresh authoritative window state.
        if (event.WindowFocusChanged !== undefined ||
            event.WindowsChanged !== undefined) {
            refreshWindows()
        }
    }

    function focusWindow(id) {
        Quickshell.execDetached([
            "niri", "msg", "action", "focus-window", "--id", String(id)
        ])
    }

    Process {
        id: eventStream
        command: ["niri", "msg", "--json", "event-stream"]
        running: true

        stdout: SplitParser {
            onRead: data => niriRoot.handleEventLine(data)
        }

        stderr: StdioCollector {
            onStreamFinished: {
                if (text.length > 0)
                    console.warn("macdock niri IPC:", text)
            }
        }

        onExited: (exitCode, exitStatus) => {
            niriRoot.connected = false
            reconnectTimer.start()
        }
    }

    Process {
        id: snapshot
        command: ["niri", "msg", "--json", "windows"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                const parsed = niriRoot.parseJson(text)
                if (parsed === null)
                    return

                let list = parsed
                if (parsed.Ok !== undefined)
                    list = parsed.Ok
                if (list && list.Windows !== undefined)
                    list = list.Windows
                if (list && list.windows !== undefined)
                    list = list.windows

                if (Array.isArray(list)) {
                    niriRoot.windows = list
                    niriRoot.connected = true
                }
            }
        }
    }

    Timer {
        id: reconnectTimer
        interval: 1500
        repeat: false
        onTriggered: eventStream.running = true
    }

    Component.onCompleted: refreshWindows()
}
