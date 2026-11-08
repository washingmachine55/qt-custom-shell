import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs

ShellRoot {
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: root

            property var modelData
            screen: modelData

            focusable: true
            visible: true
            color: "transparent"
            implicitHeight: modelData.height
            implicitWidth: modelData.width
            aboveWindows: false
            Material.theme: Material.Dark

            mask: Region {
                item: container
            }

            Item {
                id: container

                // --- TOP-LEVEL CONFIGURABLE PROPERTIES ---
                property int collapsedWidth: 240
                property int collapsedHeight: 88
                property int expandedWidth: 360
                property int expandedHeight: 380
                property int cardRadius: 28
                property int internalPadding: 16

                // Initial positioning (draggable)
                x: root.implicitWidth - expandedWidth - 60
                y: 60

                width: expanded ? expandedWidth : collapsedWidth
                height: expanded ? expandedHeight : collapsedHeight

                Behavior on width {
                    NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
                }
                Behavior on height {
                    NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
                }

                property bool expanded: false

                // Main Material Card Background
                Rectangle {
                    id: backgroundCard
                    anchors.fill: parent
                    radius: container.cardRadius
                    color: Colors.md3.surface_container_high
                    border.color: Colors.md3.outline_variant
                    border.width: 1
                }

                // --- COLLAPSED STATE ---
                Item {
                    anchors.fill: parent
                    opacity: container.expanded ? 0 : 1
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 150 } }

                    MouseArea {
                        id: collapsedDragArea
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor

                        property real startX: 0
                        property real startY: 0
                        property bool hasMoved: false

                        onPressed: mouse => {
                            startX = mouse.x;
                            startY = mouse.y;
                            hasMoved = false;
                        }

                        onPositionChanged: mouse => {
                            let deltaX = mouse.x - startX;
                            let deltaY = mouse.y - startY;

                            if (Math.abs(deltaX) > 4 || Math.abs(deltaY) > 4) {
                                hasMoved = true;
                            }

                            if (hasMoved) {
                                let nextX = container.x + deltaX;
                                let nextY = container.y + deltaY;

                                container.x = Math.max(0, Math.min(nextX, root.implicitWidth - container.width));
                                container.y = Math.max(0, Math.min(nextY, root.implicitHeight - container.height));
                            }
                        }

                        onReleased: {
                            if (!hasMoved) {
                                container.expanded = true;
                            }
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: container.internalPadding + 2
                        anchors.rightMargin: container.internalPadding + 4
                        anchors.topMargin: container.internalPadding
                        anchors.bottomMargin: container.internalPadding
                        spacing: 14

                        Rectangle {
                            Layout.preferredWidth: 52
                            Layout.preferredHeight: 52
                            radius: 14
                            color: Colors.md3.primary

                            Text {
                                anchors.centerIn: parent
                                text: Qt.formatDateTime(new Date(), "dd")
                                font.pixelSize: 22
                                font.weight: Font.Bold
                                color: Colors.md3.on_primary
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                text: Qt.formatDateTime(new Date(), "dddd")
                                font.pixelSize: 16
                                font.weight: Font.DemiBold
                                color: Colors.md3.on_surface
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            Text {
                                text: Qt.formatDateTime(new Date(), "MMMM yyyy")
                                font.pixelSize: 13
                                color: Colors.md3.on_surface_variant
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }
                    }
                }

                // --- EXPANDED STATE ---
                Item {
                    id: expandedView
                    anchors.fill: parent
                    anchors.margins: container.internalPadding
                    opacity: container.expanded ? 1 : 0
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: 150 } }

                    property date displayedDate: new Date()
                    property string viewMode: "days" // "days", "months", "years"
                    property int yearPickerBase: new Date().getFullYear()

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 6

                        // Header Bar (With strict mouse press-and-drag handling)
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            // Title & Controlled Drag Handle
                            Rectangle {
                                Layout.fillWidth: true
                                height: 32
                                radius: 8
                                color: titleMouse.containsMouse ? Colors.md3.surface_variant : "transparent"

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 6
                                    spacing: 4

                                    Text {
                                        text: expandedView.viewMode === "years"
                                              ? expandedView.yearPickerBase + " - " + (expandedView.yearPickerBase + 11)
                                              : (expandedView.viewMode === "months" ? expandedView.displayedDate.getFullYear() : Qt.formatDateTime(expandedView.displayedDate, "MMMM yyyy"))
                                        font.pixelSize: 16
                                        font.weight: Font.Bold
                                        color: Colors.md3.on_surface
                                    }
                                    Text {
                                        text: "▾"
                                        font.pixelSize: 13
                                        color: Colors.md3.primary
                                    }
                                }

                                MouseArea {
                                    id: titleMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    acceptedButtons: Qt.LeftButton

                                    property real pressX: 0
                                    property real pressY: 0
                                    property bool isDragging: false

                                    onPressed: mouse => {
                                        pressX = mouse.x;
                                        pressY = mouse.y;
                                        isDragging = false;
                                    }

                                    onPositionChanged: mouse => {
                                        // Only initiate drag if the left button is actually pressed down and moved
                                        if (pressedButtons & Qt.LeftButton) {
                                            let deltaX = mouse.x - pressX;
                                            let deltaY = mouse.y - pressY;

                                            if (Math.abs(deltaX) > 3 || Math.abs(deltaY) > 3) {
                                                isDragging = true;
                                            }

                                            if (isDragging) {
                                                let nextX = container.x + deltaX;
                                                let nextY = container.y + deltaY;

                                                container.x = Math.max(0, Math.min(nextX, root.implicitWidth - container.width));
                                                container.y = Math.max(0, Math.min(nextY, root.implicitHeight - container.height));
                                            }
                                        }
                                    }

                                    onClicked: {
                                        if (!isDragging) {
                                            if (expandedView.viewMode === "days") expandedView.viewMode = "months";
                                            else if (expandedView.viewMode === "months") expandedView.viewMode = "years";
                                            else expandedView.viewMode = "days";
                                        }
                                        isDragging = false;
                                    }
                                }
                            }

                            // Day Mode Arrows
                            RowLayout {
                                visible: expandedView.viewMode === "days"
                                spacing: 2

                                Rectangle {
                                    width: 28; height: 28; radius: 14
                                    color: prevMouse.containsMouse ? Colors.md3.surface_variant : "transparent"
                                    Text { text: "‹"; anchors.centerIn: parent; color: Colors.md3.on_surface_variant; font.pixelSize: 18 }
                                    MouseArea {
                                        id: prevMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            let d = new Date(expandedView.displayedDate);
                                            d.setMonth(d.getMonth() - 1);
                                            expandedView.displayedDate = d;
                                        }
                                    }
                                }
                                Rectangle {
                                    width: 28; height: 28; radius: 14
                                    color: nextMouse.containsMouse ? Colors.md3.surface_variant : "transparent"
                                    Text { text: "›"; anchors.centerIn: parent; color: Colors.md3.on_surface_variant; font.pixelSize: 18 }
                                    MouseArea {
                                        id: nextMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            let d = new Date(expandedView.displayedDate);
                                            d.setMonth(d.getMonth() + 1);
                                            expandedView.displayedDate = d;
                                        }
                                    }
                                }
                            }

                            // Year Mode Arrows
                            RowLayout {
                                visible: expandedView.viewMode === "years"
                                spacing: 2

                                Rectangle {
                                    width: 28; height: 28; radius: 14
                                    color: prevYMouse.containsMouse ? Colors.md3.surface_variant : "transparent"
                                    Text { text: "‹"; anchors.centerIn: parent; color: Colors.md3.on_surface_variant; font.pixelSize: 18 }
                                    MouseArea {
                                        id: prevYMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: expandedView.yearPickerBase -= 12
                                    }
                                }
                                Rectangle {
                                    width: 28; height: 28; radius: 14
                                    color: nextYMouse.containsMouse ? Colors.md3.surface_variant : "transparent"
                                    Text { text: "›"; anchors.centerIn: parent; color: Colors.md3.on_surface_variant; font.pixelSize: 18 }
                                    MouseArea {
                                        id: nextYMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: expandedView.yearPickerBase += 12
                                    }
                                }
                            }

                            // Jump to Today Button
                            Rectangle {
                                width: 28; height: 28; radius: 14
                                color: todayMouse.containsMouse ? Colors.md3.surface_variant : "transparent"
                                Text { text: "•"; anchors.centerIn: parent; color: Colors.md3.primary; font.pixelSize: 20; font.weight: Font.Bold }
                                MouseArea {
                                    id: todayMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        expandedView.displayedDate = new Date();
                                        expandedView.viewMode = "days";
                                    }
                                }
                            }

                            // Close Button
                            Rectangle {
                                width: 28; height: 28; radius: 14
                                color: closeMouse.containsMouse ? Colors.md3.surface_variant : "transparent"
                                Text { text: "✕"; anchors.centerIn: parent; color: Colors.md3.on_surface_variant; font.pixelSize: 12 }
                                MouseArea {
                                    id: closeMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        container.expanded = false;
                                        expandedView.viewMode = "days";
                                        expandedView.displayedDate = new Date();
                                    }
                                }
                            }
                        }

                        // --- DAYS GRID VIEW ---
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            visible: expandedView.viewMode === "days"

                            ColumnLayout {
                                anchors.fill: parent
                                spacing: 2

                                // Day Labels
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 0
                                    Repeater {
                                        model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
                                        Text {
                                            Layout.preferredWidth: 44
                                            horizontalAlignment: Text.AlignHCenter
                                            text: modelData
                                            font.pixelSize: 12
                                            font.weight: Font.Medium
                                            color: Colors.md3.primary
                                        }
                                    }
                                }

                                // Days Grid with Alternating Row Color Strips
                                GridLayout {
                                    id: monthGrid
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    columns: 7
                                    rowSpacing: 2
                                    columnSpacing: 0

                                    property var calendarModel: {
                                        let year = expandedView.displayedDate.getFullYear();
                                        let month = expandedView.displayedDate.getMonth();
                                        let firstDay = new Date(year, month, 1);
                                        let startingDayOfWeek = (firstDay.getDay() + 6) % 7;
                                        let lastDay = new Date(year, month + 1, 0);
                                        let totalDays = lastDay.getDate();

                                        let days = [];
                                        let prevMonthLastDay = new Date(year, month, 0).getDate();
                                        for (let i = startingDayOfWeek - 1; i >= 0; i--) {
                                            days.push({ day: prevMonthLastDay - i, currentMonth: false });
                                        }
                                        for (let i = 1; i <= totalDays; i++) {
                                            days.push({ day: i, currentMonth: true });
                                        }
                                        let targetCells = 42;
                                        let nextMonthDay = 1;
                                        while (days.length < targetCells) {
                                            days.push({ day: nextMonthDay++, currentMonth: false });
                                        }

                                        return days;
                                    }

                                    Repeater {
                                        model: monthGrid.calendarModel

                                        Rectangle {
                                            required property var modelData
                                            required property int index

                                            Layout.preferredWidth: 44
                                            Layout.preferredHeight: 34
                                            radius: 12

                                            property bool isToday: {
                                                let today = new Date();
                                                return modelData.currentMonth &&
                                                       modelData.day === today.getDate() &&
                                                       expandedView.displayedDate.getMonth() === today.getMonth() &&
                                                       expandedView.displayedDate.getFullYear() === today.getFullYear();
                                            }

                                            // Alternating row background tint
                                            property int rowIndex: Math.floor(index / 7)
                                            color: isToday ? Colors.md3.primary :
                                                   (rowIndex % 2 === 1 ? Qt.rgba(1, 1, 1, 0.03) : "transparent")

                                            Text {
                                                anchors.centerIn: parent
                                                text: modelData.day
                                                font.pixelSize: 13
                                                font.weight: parent.isToday ? Font.Bold : Font.Normal
                                                color: parent.isToday ? Colors.md3.on_primary :
                                                       modelData.currentMonth ? Colors.md3.on_surface : Colors.md3.outline
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // --- MONTH SELECTOR GRID ---
                        GridLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            columns: 3
                            rowSpacing: 6
                            columnSpacing: 6
                            visible: expandedView.viewMode === "months"

                            Repeater {
                                model: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]

                                Rectangle {
                                    required property int index
                                    required property string modelData
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    radius: 12
                                    color: expandedView.displayedDate.getMonth() === index ? Colors.md3.primary : (mMouse.containsMouse ? Colors.md3.surface_variant : "transparent")

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.substring(0, 3)
                                        font.pixelSize: 14
                                        font.weight: Font.Medium
                                        color: expandedView.displayedDate.getMonth() === index ? Colors.md3.on_primary : Colors.md3.on_surface
                                    }

                                    MouseArea {
                                        id: mMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            let d = new Date(expandedView.displayedDate);
                                            d.setMonth(index);
                                            expandedView.displayedDate = d;
                                            expandedView.viewMode = "days";
                                        }
                                    }
                                }
                            }
                        }

                        // --- YEAR SELECTOR GRID ---
                        GridLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            columns: 3
                            rowSpacing: 6
                            columnSpacing: 6
                            visible: expandedView.viewMode === "years"

                            Repeater {
                                model: 12

                                Rectangle {
                                    required property int index
                                    property int targetYear: expandedView.yearPickerBase + index

                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    radius: 12
                                    color: expandedView.displayedDate.getFullYear() === targetYear ? Colors.md3.primary : (yMouse.containsMouse ? Colors.md3.surface_variant : "transparent")

                                    Text {
                                        anchors.centerIn: parent
                                        text: parent.targetYear
                                        font.pixelSize: 14
                                        font.weight: Font.Medium
                                        color: expandedView.displayedDate.getFullYear() === parent.targetYear ? Colors.md3.on_primary : Colors.md3.on_surface
                                    }

                                    MouseArea {
                                        id: yMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            let d = new Date(expandedView.displayedDate);
                                            d.setFullYear(parent.targetYear);
                                            expandedView.displayedDate = d;
                                            expandedView.viewMode = "months";
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
