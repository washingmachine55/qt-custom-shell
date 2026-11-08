import QtQuick
import QtQuick.Controls.Material
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs

Item {
    id: container

    // --- TOP-LEVEL CONFIGURABLE PROPERTIES ---
    property int collapsedSize: 48
    property int expandedWidth: 360
    property int expandedHeight: 380
    property int cardRadius: 24
    property int internalPadding: 16

    // Animation Configuration
    property int animDuration: 350
    property var animEasing: Easing.InOutCubic // Gives a nice subtle modern spring/pop

    // Initial positioning of the widget container (draggable)
    x: 780
    y: 100

    width: expandedWidth
    height: expandedHeight

    property bool expanded: false

    // State control for layout visibility vs visual scaling
    state: expanded ? "expanded" : "collapsed"

    states: [
        State {
            name: "collapsed"
            PropertyChanges { target: cardWrapper; scale: 0.15; opacity: 0 }
            PropertyChanges { target: iconWrapper; scale: 1.0; opacity: 1 }
        },
        State {
            name: "expanded"
            PropertyChanges { target: cardWrapper; scale: 1.0; opacity: 1 }
            PropertyChanges { target: iconWrapper; scale: 0.0; opacity: 0 }
        }
    ]

    transitions: [
        Transition {
            from: "*"; to: "*"
            NumberAnimation {
                properties: "scale,opacity"
                duration: container.animDuration
                easing.type: container.animEasing
            }
        }
    ]

    // --- COLLAPSED STATE (Icon Button) ---
    Item {
        id: iconWrapper
        width: container.collapsedSize
        height: container.collapsedSize
        anchors.horizontalCenter: parent.horizontalCenter
        transformOrigin: Item.Top
        z: container.expanded ? 0 : 2

        Rectangle {
            anchors.fill: parent
            radius: container.collapsedSize / 2
            color: Colors.md3.surface_container_high
            border.color: Colors.md3.outline_variant
            border.width: 1

            MouseArea {
                id: collapsedDragArea
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton

                property point clickPos: "0,0"
                property bool hasMoved: false

                onPressed: mouse => {
                    clickPos = Qt.point(mouse.x, mouse.y);
                    hasMoved = false;
                }

                onPositionChanged: mouse => {
                    if (pressedButtons & Qt.LeftButton) {
                        let deltaX = mouse.x - clickPos.x;
                        let deltaY = mouse.y - clickPos.y;

                        if (Math.abs(deltaX) > 3 || Math.abs(deltaY) > 3) {
                            hasMoved = true;
                        }

                        if (hasMoved) {
                            container.x += deltaX;
                            container.y += deltaY;
                        }
                    }
                }

                onReleased: {
                    if (!hasMoved) {
                        container.expanded = true;
                    }
                    hasMoved = false;
                }
            }

            Text {
                anchors.centerIn: parent
                text: ""
                color: ShellState.isDarkScheme ? Colors.md3.primary : Colors.md3.inverse_primary
                font.pixelSize: 20
            }
        }
    }

    // --- EXPANDED STATE (Full Popover Card) ---
    Item {
        id: cardWrapper
        anchors.fill: parent
        transformOrigin: Item.Center
        z: container.expanded ? 2 : 0

        // Main Material Card Background
        Rectangle {
            id: backgroundCard
            anchors.fill: parent
            radius: container.cardRadius
            color: Colors.md3.surface_container_high
            border.color: Colors.md3.outline_variant
            border.width: 1
        }

        Item {
            id: expandedView
            anchors.fill: parent
            anchors.margins: container.internalPadding

            property date displayedDate: new Date()
            property string viewMode: "days"
            property int yearPickerBase: new Date().getFullYear()

            ColumnLayout {
                anchors.fill: parent
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 4

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

                            property point clickPos: "0,0"
                            property bool isDragging: false

                            onPressed: mouse => {
                                clickPos = Qt.point(mouse.x, mouse.y);
                                isDragging = false;
                            }

                            onPositionChanged: mouse => {
                                if (pressedButtons & Qt.LeftButton) {
                                    let deltaX = mouse.x - clickPos.x;
                                    let deltaY = mouse.y - clickPos.y;

                                    if (Math.abs(deltaX) > 3 || Math.abs(deltaY) > 3) {
                                        isDragging = true;
                                    }

                                    if (isDragging) {
                                        container.x += deltaX;
                                        container.y += deltaY;
                                    }
                                }
                            }

                            onReleased: {
                                if (!isDragging) {
                                    if (expandedView.viewMode === "days") expandedView.viewMode = "months";
                                    else if (expandedView.viewMode === "months") expandedView.viewMode = "years";
                                    else expandedView.viewMode = "days";
                                }
                                isDragging = false;
                            }
                        }
                    }

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

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: expandedView.viewMode === "days"

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 2

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
