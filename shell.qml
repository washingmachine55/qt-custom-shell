//@ pragma UseQApplication
import QtQuick
import Quickshell
import "./dock"

ShellRoot {
	RoundedOverlay {
		id: roundedOverlay
	}
	DateAndTime {
		id: dateAndTime
	}
	VolumeOsd {
		id: volumeOsd
	}
	// Activate	   { id: w }
	Widgets {
		id: widgets
	}
	StatusBar {
		id: statusBar
	}
	WeatherBar {
		id: weatherBar
	}
	Dock {
		id: dock
	}
}
