//@ pragma UseQApplication
import Quickshell
import QtQuick

ShellRoot {
    Loader { id: theme; source: "Theme.qml" }
    RoundedOverlay { id: roundedOverlay }
    DateAndTime    { id: dateAndTime }
    Widgets        { id: widgets }
    StatusBar      { id: statusBar }
}
