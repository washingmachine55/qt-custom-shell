import Quickshell 
import QtQuick
import QtQuick.Controls.Material
import Quickshell.Wayland

Variants {
    // Create the panel once on each monitor.
    model: Quickshell.screens

    PanelWindow {
        id: statusBar
        anchors {
            left: true
            top: true
            right: true
        }
        
        visible: true
        color: 'transparent'
        implicitHeight:30
        implicitWidth: 1920
        Material.theme: Material.Dark
        WlrLayershell.layer: WlrLayer.Bottom
        mask: Region {}

        property var modelData
        screen: modelData

        Rectangle {
            anchors.centerIn: parent
            width: 1900
            height: 30
            color: '#ca2d2d2d'
            border.color: "black"
            border.width: 1
            radius: 20
        }
    }
}