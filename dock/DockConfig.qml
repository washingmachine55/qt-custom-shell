import QtQuick

QtObject {
	id: dockConfig
    // Supported: "bottom", "top", "left", "right"
    property string edge: "bottom"

    property int iconSize: 28
    property int iconSpacing: 10
    property int padding: 12
    property int edgeMargin: 10
    property int hideDelay: 900

    // Set to false to keep the dock visible.
    property bool autoHide: true

    // Custom icon path wins; otherwise the icon theme is used.
    // appId must match niri's app_id. desktopId is the .desktop filename
    // without the ".desktop" suffix, used by gtk-launch.
    property var pinnedApps: [
        {
            name: "Terminal",
            appId: "Alacritty",
            desktopId: "Alacritty",
            icon: "utilities-terminal",
            customIcon: ""
        },
        {
            name: "Files",
            appId: "org.gnome.Nautilus",
            desktopId: "org.gnome.Nautilus",
            icon: "org.gnome.Nautilus",
            customIcon: ""
        },
        {
            name: "Zed Editor",
            appId: "dev.zed.Zed",
            desktopId: "dev.zed.Zed",
            icon: "zed",
            customIcon: ""
        }
    ]
}
