pragma Singleton
import Quickshell
import QtQuick
import Quickshell.Io


Singleton {
    id: stateRoot
    property bool isWidgetsActive: true
    property bool isDarkScheme: false

    Process {
        running: true
        command: ["sh", "-c", "gsettings get org.gnome.desktop.interface color-scheme; exec gsettings monitor org.gnome.desktop.interface color-scheme"]
        stdout: SplitParser {
            onRead: data => stateRoot.isDarkScheme = data.includes("prefer-dark")
        }
    }
}
