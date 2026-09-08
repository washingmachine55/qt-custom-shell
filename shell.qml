import Quickshell
import QtQuick

ShellRoot {
    Loader { id: theme; source: "Theme.qml" }
    RoundedOverlay { id: roundedOverlay }
    DateAndTime    { id: dateAndTime }
    // StatusBar      { id: statusBar }
}
