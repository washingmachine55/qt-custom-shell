import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

ShellRoot {
    id: weatherBar

    // ───────────── Config ─────────────
    readonly property string city: "Lahore"
    readonly property real latitude: 31.5204
    readonly property real longitude: 74.3587
    readonly property bool fahrenheit: false
    readonly property int panelWidth: 360
    readonly property int overshootPad: 40
    readonly property int triggerWidth: 6        // px hover strip on the screen edge
    readonly property int openDelay: 350         // ms hover before opening
    readonly property int closeDelay: 350        // ms after leaving before closing
    readonly property int refreshMinutes: 15
    readonly property string fontFamily: "Rubik" // falls back to default if missing

    // ───────────── Palette (Material 3 dark) ─────────────
    readonly property color cSurface: Colors.md3.surface
    readonly property color cContainer: Colors.md3.surface_container
    readonly property color cContainerHi: Colors.md3.surface_container_high
    readonly property color cPrimary: Colors.md3.primary
    readonly property color cOnSurface: Colors.md3.on_surface
    readonly property color cOnVariant: Colors.md3.on_surface_variant
    readonly property color cRain: Colors.md3.tertiary

    // ───────────── State ─────────────
    property bool open: false
    property bool hovered: false
    property bool loading: false
    property string error: ""
    property var weather: null
    property real lastFetch: 0

    // Drives the staggered reveal of each section (0 → 1)
    property real reveal: open ? 1 : 0
    Behavior on reveal {
        NumberAnimation { duration: weatherBar.open ? 800 : 200; easing.type: Easing.Linear }
    }

    function stage(i) {
        const t = Math.max(0, Math.min(1, (reveal - i * 0.09) / 0.55));
        return 1 - Math.pow(1 - t, 3);
    }

    function spring(i) {   // ease-out-back
        const t = Math.max(0, Math.min(1, (reveal - i * 0.09) / 0.55));
        return 1 + 2.9 * Math.pow(t - 1, 3) + 1.9 * Math.pow(t - 1, 2);
    }

    onHoveredChanged: {
        if (hovered) { closeTimer.stop(); openTimer.restart(); }
        else { openTimer.stop(); closeTimer.restart(); }
    }

    Timer {
        id: openTimer
        interval: weatherBar.openDelay
        onTriggered: { weatherBar.open = true; weatherBar.refreshIfStale(); }
    }
    Timer {
        id: closeTimer
        interval: weatherBar.closeDelay
        onTriggered: weatherBar.open = false
    }
    Timer {
        interval: weatherBar.refreshMinutes * 60000
        running: true
        repeat: true
        onTriggered: weatherBar.fetchWeather()
    }
    Component.onCompleted: fetchWeather()

    // ───────────── Data ─────────────
    function refreshIfStale() {
        if (Date.now() - lastFetch > 10 * 60000) fetchWeather();
    }

    function fetchWeather() {
        if (loading) return;
        loading = true;
        error = "";
        const url = "https://api.open-meteo.com/v1/forecast"
            + "?latitude=" + latitude + "&longitude=" + longitude
            + "&current=temperature_2m,relative_humidity_2m,apparent_temperature,is_day,weather_code,surface_pressure,wind_speed_10m"
            + "&hourly=temperature_2m,weather_code,is_day"
            + "&daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset,precipitation_probability_max"
            + "&forecast_days=5&timezone=auto"
            + (fahrenheit ? "&temperature_unit=fahrenheit&wind_speed_unit=mph" : "");

        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE) return;
            weatherBar.loading = false;
            if (xhr.status !== 200) {
                weatherBar.error = "Couldn't reach the weather service";
                return;
            }
            try {
                weatherBar.weather = weatherBar.parse(JSON.parse(xhr.responseText));
                weatherBar.lastFetch = Date.now();
            } catch (e) {
                weatherBar.error = "Unexpected response from the weather service";
            }
        };
        xhr.open("GET", url);
        xhr.send();
    }

    function hhmm(s) {
        const h = parseInt(s.substring(11, 13));
        return (h % 12 || 12) + ":" + s.substring(14, 16) + (h < 12 ? " AM" : " PM");
    }

    function parse(d) {
        const c = d.current, h = d.hourly, dl = d.daily;

        const hours = [];
        for (let i = 0; i < h.time.length && hours.length < 6; i++) {
            if (h.time[i] > c.time) {
                const hr = parseInt(h.time[i].substring(11, 13));
                hours.push({
                    label: (hr % 12 || 12) + (hr < 12 ? " AM" : " PM"),
                    temp: Math.round(h.temperature_2m[i]),
                    code: h.weather_code[i],
                    day: h.is_day[i] === 1
                });
            }
        }

        const days = [];
        for (let i = 0; i < dl.time.length; i++) {
            days.push({
                name: i === 0 ? "Today" : Qt.formatDate(new Date(dl.time[i] + "T12:00:00"), "ddd"),
                code: dl.weather_code[i],
                max: Math.round(dl.temperature_2m_max[i]),
                min: Math.round(dl.temperature_2m_min[i]),
                rain: dl.precipitation_probability_max[i] ?? 0
            });
        }

        return {
            temp: Math.round(c.temperature_2m),
            feels: Math.round(c.apparent_temperature),
            humidity: Math.round(c.relative_humidity_2m),
            wind: Math.round(c.wind_speed_10m),
            pressure: Math.round(c.surface_pressure),
            code: c.weather_code,
            day: c.is_day === 1,
            rain: days[0].rain,
            sunrise: hhmm(dl.sunrise[0]),
            sunset: hhmm(dl.sunset[0]),
            hours: hours,
            days: days,
            gmin: Math.min.apply(null, days.map(x => x.min)),
            gmax: Math.max.apply(null, days.map(x => x.max))
        };
    }

    // WMO weather codes → emoji + label
    function info(code, day) {
        if (code === 0) return { icon: day ? "☀️" : "🌙", text: "Clear sky" };
        if (code === 1) return { icon: day ? "🌤️" : "🌙", text: "Mainly clear" };
        if (code === 2) return { icon: day ? "⛅" : "☁️", text: "Partly cloudy" };
        if (code === 3) return { icon: "☁️", text: "Overcast" };
        if (code === 45 || code === 48) return { icon: "🌫️", text: "Fog" };
        if (code >= 51 && code <= 55) return { icon: "🌦️", text: "Drizzle" };
        if (code === 56 || code === 57) return { icon: "🌧️", text: "Freezing drizzle" };
        if (code >= 61 && code <= 65) return { icon: "🌧️", text: "Rain" };
        if (code === 66 || code === 67) return { icon: "🌧️", text: "Freezing rain" };
        if (code >= 71 && code <= 77) return { icon: "❄️", text: "Snow" };
        if (code >= 80 && code <= 82) return { icon: "🌦️", text: "Rain showers" };
        if (code === 85 || code === 86) return { icon: "🌨️", text: "Snow showers" };
        if (code === 95) return { icon: "⛈️", text: "Thunderstorm" };
        if (code === 96 || code === 99) return { icon: "⛈️", text: "Thunderstorm with hail" };
        return { icon: "🌡️", text: "Unknown" };
    }

    function tint(code, day) {
        if (code === 0 || code === 1) return day ? "#6b4e16" : "#2a2f5c";
        if (code === 2 || code === 3) return "#3d4150";
        if (code === 45 || code === 48) return "#44444f";
        if (code >= 71 && code <= 77 || code === 85 || code === 86) return "#33505f";
        if (code >= 95) return "#3b2a5a";
        return "#1f3a5a";
    }

    readonly property string tUnit: fahrenheit ? "°F" : "°C"
    readonly property string wUnit: fahrenheit ? "mph" : "km/h"

    // ───────────── Window ─────────────
    PanelWindow {
        id: win

        // Only anchored right → compositor centers it vertically.
        anchors.right: true
        // implicitWidth: weatherBar.panelWidth
        implicitWidth: weatherBar.panelWidth + weatherBar.overshootPad
        implicitHeight: content.implicitHeight + 48
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "weather-panel"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        // Hidden: only a thin strip on the edge takes input. Open: whole panel.
        mask: Region { item: hit }

        Item {
            id: hit
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            // width: weatherBar.open ? win.width : weatherBar.triggerWidth
            width: weatherBar.open ? weatherBar.panelWidth : weatherBar.triggerWidth
        }

        Item {
            anchors.fill: parent
            HoverHandler {
                onHoveredChanged: weatherBar.hovered = hovered
            }
        }

        // ── Sliding panel ──
        Rectangle {
            id: panel
            width: weatherBar.panelWidth
            height: parent.height
            radius: 28
            color: weatherBar.cSurface
            // opacity: Math.min(1, weatherBar.reveal * 5)
            opacity: Math.max(Math.min(1, weatherBar.reveal * 5), weatherBar.hovered ? 1 : 0)
            transformOrigin: Item.Right
            scale: 0.94 + 0.06 * weatherBar.spring(0)

            // x: weatherBar.open ? 0 : weatherBar.panelWidth + 24
            // x: weatherBar.open ? weatherBar.overshootPad : weatherBar.panelWidth + weatherBar.overshootPad + 24
            x: weatherBar.open ? weatherBar.overshootPad
                : weatherBar.hovered ? weatherBar.panelWidth + weatherBar.overshootPad - 16
                : weatherBar.panelWidth + weatherBar.overshootPad + 24
            Behavior on x {
                NumberAnimation {
                    duration: weatherBar.open ? 700 : 300
                    easing.type: Easing.BezierSpline
                    // M3 emphasized decelerate / accelerate
                    easing.bezierCurve: weatherBar.open
                        // ? [0.05, 0.7, 0.1, 1.0, 1.0, 1.0]
                        ? [0.3, 1.5, 0.45, 1.0, 1.0, 1.0]
                        : [0.3, 0.0, 0.8, 0.15, 1.0, 1.0]
                }
            }

            // Flatten the corners that touch the screen edge
            Rectangle {
                anchors.right: parent.right
                width: 28
                height: parent.height
                color: weatherBar.cSurface
            }

            ColumnLayout {
                id: content
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 22
                anchors.topMargin: 24
                spacing: 14

                // ── 0: Header ──
                RowLayout {
                    Layout.fillWidth: true
                    opacity: weatherBar.stage(0)
                    transform: Translate { x: (1 - weatherBar.spring(0)) * 48 }

                    ColumnLayout {
                        spacing: 0
                        Text {
                            text: weatherBar.city
                            color: weatherBar.cOnSurface
                            font.family: weatherBar.fontFamily
                            font.pixelSize: 20
                            font.weight: Font.Medium
                        }
                        Text {
                            text: weatherBar.loading ? "Updating…"
                            : weatherBar.lastFetch > 0 ? "Updated " + Qt.formatTime(new Date(weatherBar.lastFetch), "hh:mm")
                                : ""
                            color: weatherBar.cOnVariant
                            font.family: weatherBar.fontFamily
                            font.pixelSize: 12
                        }
                    }
                    Item { Layout.fillWidth: true }

                    Rectangle {
                        Layout.preferredWidth: 36
                        Layout.preferredHeight: 36
                        radius: 18
                        color: refreshArea.containsMouse ? weatherBar.cContainerHi : weatherBar.cContainer
                        scale: refreshArea.pressed ? 0.9 : 1
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }

                        Text {
                            id: spinner
                            anchors.centerIn: parent
                            text: "↻"
                            color: weatherBar.cPrimary
                            font.pixelSize: 20
                            NumberAnimation on rotation {
                                from: 0; to: 360; duration: 900
                                loops: Animation.Infinite
                                running: weatherBar.loading
                                onRunningChanged: if (!running) spinner.rotation = 0
                            }
                        }
                        MouseArea {
                            id: refreshArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: weatherBar.fetchWeather()
                        }
                    }
                }

                // ── Status (loading / error) ──
                Text {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 160
                    visible: weatherBar.weather === null
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    wrapMode: Text.WordWrap
                    text: weatherBar.error !== "" ? weatherBar.error + "\nClick ↻ to retry" : "Loading weather…"
                    color: weatherBar.cOnVariant
                    font.family: weatherBar.fontFamily
                    font.pixelSize: 14
                }

                // ── 1: Hero ──
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 150
                    visible: weatherBar.weather !== null
                    radius: 24
                    opacity: weatherBar.stage(1)
                    transform: Translate { x: (1 - weatherBar.spring(1)) * 48 }

                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop {
                            position: 0
                            color: weatherBar.weather ? weatherBar.tint(weatherBar.weather.code, weatherBar.weather.day) : weatherBar.cContainer
                            Behavior on color { ColorAnimation { duration: 600 } }
                        }
                        GradientStop { position: 1; color: weatherBar.cContainer }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 18

                        ColumnLayout {
                            spacing: 0
                            Text {
                                text: weatherBar.weather ? weatherBar.weather.temp + "°" : ""
                                color: weatherBar.cOnSurface
                                font.family: weatherBar.fontFamily
                                font.pixelSize: 64
                                font.weight: Font.Light
                            }
                            Text {
                                text: weatherBar.weather ? weatherBar.info(weatherBar.weather.code, weatherBar.weather.day).text : ""
                                color: weatherBar.cOnSurface
                                font.family: weatherBar.fontFamily
                                font.pixelSize: 16
                                font.weight: Font.Medium
                            }
                            Text {
                                text: weatherBar.weather ? "Feels like " + weatherBar.weather.feels + weatherBar.tUnit : ""
                                color: weatherBar.cOnVariant
                                font.family: weatherBar.fontFamily
                                font.pixelSize: 12
                            }
                        }
                        Item { Layout.fillWidth: true }
                        Item {
                            Layout.preferredWidth: 96
                            Layout.preferredHeight: 96
                            Text {
                                id: heroIcon
                                anchors.centerIn: parent
                                text: weatherBar.weather ? weatherBar.info(weatherBar.weather.code, weatherBar.weather.day).icon : ""
                                font.pixelSize: 76
                                scale: 0.4 + 0.6 * weatherBar.spring(1)

                                // Gentle idle float, only while visible
                                SequentialAnimation on anchors.verticalCenterOffset {
                                    running: weatherBar.open
                                    loops: Animation.Infinite
                                    NumberAnimation { to: -5; duration: 1800; easing.type: Easing.InOutSine }
                                    NumberAnimation { to: 5; duration: 1800; easing.type: Easing.InOutSine }
                                }
                            }
                        }
                    }
                }

                // ── 2: Stats ──
                GridLayout {
                    Layout.fillWidth: true
                    visible: weatherBar.weather !== null
                    columns: 2
                    rowSpacing: 10
                    columnSpacing: 10
                    opacity: weatherBar.stage(2)
                    transform: Translate { x: (1 - weatherBar.spring(2)) * 48 }

                    Repeater {
                        model: weatherBar.weather ? [
                        { icon: "💧", label: "Humidity", value: weatherBar.weather.humidity + "%" },
                        { icon: "💨", label: "Wind", value: weatherBar.weather.wind + " " + weatherBar.wUnit },
                        { icon: "☔", label: "Rain chance", value: weatherBar.weather.rain + "%" },
                        { icon: "🧭", label: "Pressure", value: weatherBar.weather.pressure + " hPa" }
                        ] : []

                        delegate: Rectangle {
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.preferredHeight: 62
                            radius: 18
                            color: weatherBar.cContainer

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 14
                                anchors.rightMargin: 10
                                spacing: 10
                                Text { text: modelData.icon; font.pixelSize: 22 }
                                ColumnLayout {
                                    spacing: 0
                                    Text {
                                        text: modelData.label
                                        color: weatherBar.cOnVariant
                                        font.family: weatherBar.fontFamily
                                        font.pixelSize: 11
                                    }
                                    Text {
                                        text: modelData.value
                                        color: weatherBar.cOnSurface
                                        font.family: weatherBar.fontFamily
                                        font.pixelSize: 15
                                        font.weight: Font.Medium
                                    }
                                }
                            }
                        }
                    }
                }

                // ── 3: Hourly ──
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 92
                    visible: weatherBar.weather !== null
                    radius: 20
                    color: weatherBar.cContainer
                    opacity: weatherBar.stage(3)
                    transform: Translate { x: (1 - weatherBar.spring(3)) * 48 }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 0

                        Repeater {
                            model: weatherBar.weather ? weatherBar.weather.hours : []
                            delegate: ColumnLayout {
                                required property var modelData
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                spacing: 2
                                Item { Layout.fillHeight: true }
                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: modelData.label
                                    color: weatherBar.cOnVariant
                                    font.family: weatherBar.fontFamily
                                    font.pixelSize: 10
                                }
                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: weatherBar.info(modelData.code, modelData.day).icon
                                    font.pixelSize: 22
                                }
                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: modelData.temp + "°"
                                    color: weatherBar.cOnSurface
                                    font.family: weatherBar.fontFamily
                                    font.pixelSize: 13
                                    font.weight: Font.Medium
                                }
                                Item { Layout.fillHeight: true }
                            }
                        }
                    }
                }

                // ── 4: Daily forecast ──
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: dailyCol.implicitHeight + 24
                    visible: weatherBar.weather !== null
                    radius: 20
                    color: weatherBar.cContainer
                    opacity: weatherBar.stage(4)
                    transform: Translate { x: (1 - weatherBar.spring(4)) * 48 }

                    ColumnLayout {
                        id: dailyCol
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 4

                        Repeater {
                            model: weatherBar.weather ? weatherBar.weather.days : []
                            delegate: RowLayout {
                                required property var modelData
                                Layout.fillWidth: true
                                Layout.preferredHeight: 30
                                spacing: 8

                                Text {
                                    Layout.preferredWidth: 46
                                    text: modelData.name
                                    color: weatherBar.cOnSurface
                                    font.family: weatherBar.fontFamily
                                    font.pixelSize: 13
                                }
                                Text {
                                    text: weatherBar.info(modelData.code, true).icon
                                    font.pixelSize: 18
                                }
                                Text {
                                    Layout.preferredWidth: 32
                                    text: modelData.rain + "%"
                                    color: weatherBar.cRain
                                    font.family: weatherBar.fontFamily
                                    font.pixelSize: 11
                                    horizontalAlignment: Text.AlignRight
                                }
                                Text {
                                    Layout.preferredWidth: 26
                                    text: modelData.min + "°"
                                    color: weatherBar.cOnVariant
                                    font.family: weatherBar.fontFamily
                                    font.pixelSize: 12
                                    horizontalAlignment: Text.AlignRight
                                }

                                // Min–max range bar (grows in with the reveal)
                                Item {
                                    id: track
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 6
                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 3
                                        color: weatherBar.cContainerHi
                                    }
                                    Rectangle {
                                        readonly property real span: Math.max(1, weatherBar.weather.gmax - weatherBar.weather.gmin)
                                        height: parent.height
                                        radius: 3
                                        color: weatherBar.cPrimary
                                        x: (modelData.min - weatherBar.weather.gmin) / span * track.width
                                        width: Math.max(6, (modelData.max - modelData.min) / span * track.width) * weatherBar.stage(4)
                                    }
                                }

                                Text {
                                    Layout.preferredWidth: 26
                                    text: modelData.max + "°"
                                    color: weatherBar.cOnSurface
                                    font.family: weatherBar.fontFamily
                                    font.pixelSize: 12
                                    font.weight: Font.Medium
                                }
                            }
                        }
                    }
                }

                // ── 5: Sunrise / sunset ──
                RowLayout {
                    Layout.fillWidth: true
                    visible: weatherBar.weather !== null
                    opacity: weatherBar.stage(5)
                    transform: Translate { x: (1 - weatherBar.spring(5)) * 48 }

                    Text {
                        text: "🌅 " + (weatherBar.weather ? weatherBar.weather.sunrise : "")
                        color: weatherBar.cOnVariant
                        font.family: weatherBar.fontFamily
                        font.pixelSize: 12
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: "🌇 " + (weatherBar.weather ? weatherBar.weather.sunset : "")
                        color: weatherBar.cOnVariant
                        font.family: weatherBar.fontFamily
                        font.pixelSize: 12
                    }
                }
            }
        }
    }
}
