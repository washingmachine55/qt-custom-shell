import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.SystemTray

Variants {
    model: Quickshell.screens

    delegate: Component {
        PanelWindow {
            id: statusBar

            required property var modelData
            required property bool isVisible
            isVisible: true

            screen: modelData

            // anchors {
            //     left: true
            //     top: true
            //     right: true
            // }

            visible: true
            color: "transparent"
            implicitHeight: screen.height / 6
            implicitWidth: screen.width / 3
            WlrLayershell.layer: WlrLayer.Bottom

            property string cpuPercent: "0%"
            property string ramPercent: "0%"
            property string swapPercent: "0%"
            property string sysUptime: "0m"
            property string activekeyboardLayout: "(US)"
            property string activeWinTitle: "Desktop"
            property string mediaStatus: "No Media"
            property bool use12Hour: true
            property var workspacesList: []

            // --- Fixed System Monitor Process ---
            Process {
                id: sysMonProcess
                command: ["sh", "-c", "echo \"$(top -bn1 | grep 'Cpu(s)' | awk '{print int($2+$4)}');$(free | awk '/Mem:/{printf \"%d;\", $3/$2*100} /Swap:/{printf \"%d\", $3/$2*100}');$(uptime -p | sed -e 's/up //' -e 's/ hours\?/h/g' -e 's/ minutes\?/m/g' -e 's/ hour\?/h/g' -e 's/ minute\?/m/g')\""]
                stdout: SplitParser {
                    onRead: data => {
                        let sections = data.trim().split(";");
                        if (sections.length >= 4) {
                            statusBar.cpuPercent = (sections[0] || "0") + "%";
                            statusBar.ramPercent = (sections[1] || "0") + "%";
                            statusBar.swapPercent = (sections[2] || "0") + "%";
                            statusBar.sysUptime = sections[3] || "0m";
                        }
                    }
                }
            }

            property string networkSpeed: "0 B/s ↓↑ 0 B/s"

            Process {
                id: netMonProcess
                command: ["/home/devmed/qt-custom-shell/scripts/networkSpeed.sh"]
                stdout: SplitParser {
                            splitMarker: "\n"
                            onRead: (data) => {
                                if (!data || data.trim() === "") return;
                                try {
                                    // 2. Parse the individual JSON line
                                    let json = JSON.parse(data.trim());
                                    // 3. Extract the "text" key and update the QML property
                                    if (json && json.text !== undefined) {
                                        statusBar.networkSpeed = json.text;
                                    }
                                } catch (e) {
                                    console.error("Failed to parse network speed JSON:", e);
                                }
                            }
                        }
            }

            // --- Niri Workspaces Fetcher ---
            Process {
                id: niriWorkspacesProcess
                command: ["sh", "-c", "niri msg -j workspaces"]
                stdout: SplitParser {
                    onRead: data => {
                        try {
                            let parsed = JSON.parse(data);
                            statusBar.workspacesList = parsed;
                        } catch (e) {}
                    }
                }
            }

            Process {
                id: keyboardLayoutProcess
                command: ["/home/devmed/.config/waybar/scripts/check-current-keyboard-layout-niri.sh"]
                stdout: SplitParser {
                    onRead: data => statusBar.activekeyboardLayout = data.trim()
                }
            }

            Process {
                id: mediaProcess
                command: ["playerctl", "metadata", "--format", "{{artist}} - {{title}}"]
                stdout: SplitParser {
                    onRead: data => statusBar.mediaStatus = data.trim() || "No Media"
                }
            }

            Process {
                id: activeWinProcess
                command: ["sh", "-c", "niri msg action focused-window | grep -E 'Title:|App ID:' | head -n 1 | awk -F': ' '{print $2}'"]
                stdout: SplitParser {
                    onRead: data => statusBar.activeWinTitle = data.trim() || "Desktop"
                }
            }

            Timer {
                interval: 2000
                running: true
                repeat: true
                triggeredOnStart: true
                onTriggered: {
                    sysMonProcess.running = true;
                    niriWorkspacesProcess.running = true;
                    keyboardLayoutProcess.running = true;
                    mediaProcess.running = true;
                    activeWinProcess.running = true;
                    netMonProcess.running = true;
                }
            }

            function exec(cmd) {
                cmdProcess.command = typeof cmd === "string" ? [cmd] : cmd;
                cmdProcess.running = true;
            }

            Process {
                id: cmdProcess
            }

            readonly property color colBarBg: "#e6000000"
            readonly property color colBarBorder: "#1ae6e8ee"
            readonly property color colAccent: "#9acbfa"
            readonly property color colAccentMuted: "#0a4a72"
            readonly property color colHoverBg: "#0a4a72"
            readonly property color colTextMain: "#9acbfa"
            readonly property color colTextMuted: "#2d628c"
            readonly property color colSuccess: "#30d158"

            Rectangle {
                id: rekt
                anchors.fill: parent
                color: statusBar.colBarBg
                // color: "transparent"
                radius: 17.5

                // Bottom border
                // Rectangle {
                //     anchors.left: parent.left
                //     anchors.right: parent.right
                //     anchors.bottom: parent.bottom
                //     height: 1
                //     color: colBarBorder
                // }

                ColumnLayout {
                    anchors.fill: rekt
                    anchors.topMargin: 2
                    anchors.bottomMargin: 0
                    anchors.leftMargin: 4
                    anchors.rightMargin: 4
                    spacing: 6

                    // ==========================================
                    // MODULES LEFT
                    // ==========================================
                    RowLayout {
                        spacing: 6
                        Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter

                        Row {
                            // Uptime Module
                            Rectangle {
                                id: uptimePill
                                implicitWidth: uptimeHoverArea.containsMouse ? uptimeText.implicitWidth + 18 : 28
                                height: 24
                                radius: 12
                                color: uptimeHoverArea.containsMouse ? statusBar.colHoverBg : "transparent"
                                border.color: statusBar.colAccentMuted
                                border.width: 1

                                Behavior on implicitWidth {
                                    NumberAnimation {
                                        duration: 150
                                        easing.type: Easing.InOutQuad
                                    }
                                }
                                Behavior on color {
                                    ColorAnimation {
                                        duration: 150
                                    }
                                }

                                Text {
                                    id: uptimeText
                                    anchors.centerIn: parent
                                    text: uptimeHoverArea.containsMouse ? "↑ " + statusBar.sysUptime : "↑"
                                    font.family: "JetBrainsMonoNL Nerd Font"
                                    font.pixelSize: 12
                                    color: statusBar.colAccent
                                }

                                MouseArea {
                                    id: uptimeHoverArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                }
                            }
                        }
                        Item {
                            Layout.fillWidth: true
                        }
                        Row {
                            // System Stats Pill
                            Rectangle {
                                implicitWidth: pillRow.implicitWidth + 16
                                height: 24
                                radius: 12
                                color: sysPillMouse.containsMouse ? statusBar.colHoverBg : "transparent"
                                border.color: statusBar.colAccentMuted
                                border.width: 1

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 150
                                    }
                                }

                                MouseArea {
                                    id: sysPillMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                }

                                Row {
                                    id: pillRow
                                    anchors.centerIn: parent
                                    spacing: 10

                                    Text {
                                        text: "  " + statusBar.cpuPercent
                                        font.family: "JetBrainsMonoNL Nerd Font"
                                        font.pixelSize: 12
                                        color: statusBar.colAccent
                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: statusBar.exec(["alacritty", "--class=Btop", "-e", "btop"])
                                        }
                                    }

                                    Text {
                                        text: "|"
                                        color: statusBar.colAccentMuted
                                        font.pixelSize: 10
                                    }

                                    Text {
                                        text: "  " + statusBar.ramPercent
                                        font.family: "JetBrainsMonoNL Nerd Font"
                                        font.pixelSize: 12
                                        color: statusBar.colAccent
                                    }

                                    Text {
                                        text: "|"
                                        color: statusBar.colAccentMuted
                                        font.pixelSize: 10
                                    }

                                    Text {
                                        text: "⇄  " + statusBar.swapPercent
                                        font.family: "JetBrainsMonoNL Nerd Font"
                                        font.pixelSize: 12
                                        color: statusBar.colAccent
                                    }

                                    Text {
                                        text: "|"
                                        color: statusBar.colAccentMuted
                                        font.pixelSize: 10
                                    }

                                    Text {
                                        text: statusBar.networkSpeed
                                        font.family: "JetBrainsMonoNL Nerd Font"
                                        font.pixelSize: 12
                                        color: statusBar.colAccent
                                    }

                                }
                            }
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    // ==========================================
                    // MODULES CENTER
                    // ==========================================
                    Row {
                        Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                        spacing: 6

                        BarModule {
                            id: clockModule
                            fontBold: true
                            textColor: statusBar.colAccent

                            property var time: new Date()
                            Timer {
                                interval: 1000
                                running: true
                                repeat: true
                                onTriggered: clockModule.time = new Date()
                            }

                            text: Qt.formatDateTime(time, statusBar.use12Hour ? "hh:mm:ss AP '' dddd, MMMM dd, yyyy" : "HH:mm:ss '' dddd, MMMM dd, yyyy")
                            onClicked: mouse => {
                                if (mouse.button === Qt.LeftButton) {
                                    statusBar.use12Hour = !statusBar.use12Hour;
                                } else if (mouse.button === Qt.MiddleButton) {
                                    statusBar.exec(["sh", "-c", "date +%F' '%r | wl-copy"]);
                                }
                            }
                        }

                        BarModule {
                            id: keyboardLayoutModule
                            property int layoutIdx: 0
                            property var layouts: ["US", "CDH"]
                            // text: "[ " + layouts[layoutIdx] + " ]"
                            text: "[ " + statusBar.activekeyboardLayout + " ]"
                            textColor: statusBar.colTextMuted
                            onClicked: {
                                statusBar.exec(["niri", "msg", "action", "switch-layout", "next"]);
                            }
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    // ==========================================
                    // MODULES RIGHT
                    // ==========================================
                    RowLayout {
                        id: bottomRow
                        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                        spacing: 6

                        Row {
                            spacing: 4
                            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                            // anchors.verticalCenter: parent.verticalCenter

                            Repeater {
                                model: SystemTray.items

                                delegate: Item {
                                    id: trayItem
                                    required property SystemTrayItem modelData

                                    width: 22
                                    height: 22

                                    // 1. Declare the anchor inside Quickshell's QML engine
                                    QsMenuAnchor {
                                        id: trayMenuAnchor
                                        menu: trayItem.modelData.menu
                                    }

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 6
                                        color: trayMouse.containsMouse ? statusBar.colHoverBg : "transparent"

                                        Image {
                                            anchors.centerIn: parent
                                            width: 16
                                            height: 16
                                            fillMode: Image.PreserveAspectFit
                                            smooth: true
                                            source: {
                                                if (!trayItem.modelData.icon)
                                                    return "";
                                                if (trayItem.modelData.icon.startsWith("/") || trayItem.modelData.icon.startsWith("file://")) {
                                                    return trayItem.modelData.icon;
                                                }
                                                // return "image://icon/" + trayItem.modelData.icon;
                                                return trayItem.modelData.icon;
                                            }
                                        }

                                        MouseArea {
                                            id: trayMouse
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            acceptedButtons: Qt.LeftButton | Qt.RightButton

                                            onClicked: mouse => {
                                                if (mouse.button === Qt.LeftButton) {
                                                    trayItem.modelData.activate();
                                                } else if (mouse.button === Qt.RightButton && trayItem.modelData.hasMenu) {
                                                    trayItem.modelData.display(statusBar, 0, 0);
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        Item {
                            Layout.fillWidth: true
                        }
                        Row {
                            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                            spacing: 2

                            BarModule {
                                text: "󰂜"
                                textColor: statusBar.colTextMain
                                onClicked: mouse => {
                                    if (mouse.button === Qt.LeftButton)
                                        statusBar.exec(["swaync-client", "-t", "-sw"]);
                                    else if (mouse.button === Qt.RightButton)
                                        statusBar.exec(["swaync-client", "-d", "-sw"]);
                                }
                            }

                            BarModule {
                                text: " " + statusBar.mediaStatus
                                textColor: statusBar.colAccent
                                implicitWidth: Math.min(moduleText.implicitWidth + 18, 200)
                                onClicked: statusBar.exec(["playerctl", "play-pause"])
                            }

                            BarModule {
                                text: "󰂯"
                                textColor: statusBar.colAccent
                                onClicked: statusBar.exec(["kitty", "--app-id=bluetui", "bluetui"])
                            }

                            BarModule {
                                text: "󰤢"
                                textColor: statusBar.colTextMain
                                onClicked: statusBar.exec(["kitty", "--app-id=impala", "impala"])
                            }

                            BarModule {
                                text: ""
                                textColor: statusBar.colTextMain
                                onClicked: mouse => {
                                    if (mouse.button === Qt.LeftButton)
                                        statusBar.exec(["kitty", "--app-id=wiremix", "-e", "wiremix"]);
                                    else if (mouse.button === Qt.RightButton)
                                        statusBar.exec(["pactl", "set-sink-mute", "@DEFAULT-SINK@", "toggle"]);
                                }
                            }

                            BarModule {
                                text: ""
                                textColor: statusBar.colSuccess
                            }
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }
                }
            }
        }
    }

    component BarModule: Rectangle {
        id: moduleRoot
        property alias text: moduleText.text
        property alias textColor: moduleText.color
        property alias fontBold: moduleText.font.bold
        signal clicked(var mouse)

        implicitWidth: moduleText.implicitWidth + 18
        implicitHeight: 24
        radius: 12
        color: moduleArea.containsMouse ? statusBar.colHoverBg : "transparent"

        Behavior on color {
            ColorAnimation {
                duration: 150
            }
        }

        Text {
            id: moduleText
            anchors.centerIn: parent
            font.family: "JetBrainsMonoNL Nerd Font, Inter, sans-serif"
            font.pixelSize: 13
            color: statusBar.colTextMain
        }

        MouseArea {
            id: moduleArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
            onClicked: mouse => moduleRoot.clicked(mouse)
        }
    }
}
