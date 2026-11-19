//@ pragma UseQApplication
import QtQuick
import Quickshell
import "./dock"

ShellRoot {
	// Activate {
	// 	id: w
	// }
	// StatusBar {
	// 	id: statusBar
	// }
	RoundedOverlay {
		id: roundedOverlay
	}
	DateAndTime {
		id: dateAndTime
	}
	VolumeOsd {
		id: volumeOsd
	}
	Widgets {
		id: widgets
	}
	WeatherBar {
		id: weatherBar
	}
	Dock {
		id: dock
	}
}
