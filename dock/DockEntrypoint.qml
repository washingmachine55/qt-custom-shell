import QtQuick
import Quickshell

Scope {
    DockConfig {
        id: dockConfig
    }

    Niri {
        id: niriState
    }

    Variants {
        model: Quickshell.screens

        DockPanel {
            required property var modelData
            screen: modelData
            config: dockConfig
            niri: niriState
        }
    }
}
