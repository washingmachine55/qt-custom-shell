import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Widgets
import Qt5Compat.GraphicalEffects

Scope {
    id: volumeOsd

    // Bind the pipewire node so its volume will be tracked
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    Connections {
        target: Pipewire.defaultAudioSink?.audio

        function onVolumeChanged() {
            volumeOsd.shouldShowOsd = true;
            hideTimer.restart();
        }
    }

    property bool shouldShowOsd: false

    Timer {
        id: hideTimer
        interval: 2000
        onTriggered: volumeOsd.shouldShowOsd = false
    }

    // The OSD window will be created and destroyed based on shouldShowOsd.
    // PanelWindow.visible could be set instead of using a loader, but using
    // a loader will reduce the memory overhead when the window isn't open.
    LazyLoader {
        active: volumeOsd.shouldShowOsd

        PanelWindow {
            // Since the panel's screen is unset, it will be picked by the compositor
            // when the window is created. Most compositors pick the current active monitor.

            anchors.top: true
            margins.top: screen.height / 48
            exclusiveZone: 0

            implicitWidth: 400
            implicitHeight: 50
            color: "transparent"

            // An empty click mask prevents the window from blocking mouse events.
            mask: Region {}

            Rectangle {
                id: myBox
                anchors.fill: parent
                radius: height / 2
                color: Colors.md3.primary_container
                opacity: 0.85

                RowLayout {
                    anchors {
                        fill: parent
                        leftMargin: 15
                        rightMargin: 15
                    }
                    spacing: 10

                    Item {
                        id: iconWrapper
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter

                        IconImage {
                            id: speakerIcon
                            implicitSize: 28
                            visible: false
                            source: Quickshell.iconPath("audio-speaker-left-side")
                        }

                        ColorOverlay {
                            anchors.fill: speakerIcon
                            source: speakerIcon
                            color: Colors.md3.primary
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.rightMargin: 8
                        implicitHeight: 10
                        radius: 20
                        color: Colors.md3.on_primary

                        Rectangle {
                            anchors {
                                left: parent.left
                                top: parent.top
                                bottom: parent.bottom
                            }
                            color: Colors.md3.primary

                            implicitWidth: parent.width * (Pipewire.defaultAudioSink?.audio.volume ?? 0)
                            radius: parent.radius
                        }
                    }

                    Rectangle {
                        // Stretches to fill all left-over space
                        Layout.fillWidth: false

                        implicitHeight: 28
                        implicitWidth: 28
                        radius: 20
                        color: "#50ffff80"

                        Text {
                            id: name
                            text: Math.trunc(Pipewire.defaultAudioSink?.audio.volume * 100)
                            color: "white"
                            anchors.centerIn: parent
                        }
                    }
                }
            }
        }
    }
}
