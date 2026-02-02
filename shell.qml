import Quickshell 
import QtQuick

ShellRoot {
    Loader { id: roundedOverlay; source: "roundedOverlay.qml" }
    Loader { id: dateAndTime; source: "dateAndTime.qml" }
    Loader { id: theme; source: "Theme.qml" }
    // Loader { id: statusBar; source: "statusBar.qml" }
}
