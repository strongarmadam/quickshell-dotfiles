//@ pragma IconTheme Adwaita
import "./widgets" as Config
import "./widgets"
import Quickshell
import QtQuick

ShellRoot {
    id: root
    ParallaxWallpaper {}
    SystemMonitor { id: monitor }
    WidgetLayout { id: layout }

    MovableWidget {
        layoutManager: layout
        widgetId: "cpu"
        implicitWidth: Config.Settings.value("Coral Lagoon", "shell", "implicitWidth", 260)
        implicitHeight: Config.Settings.value("Coral Lagoon", "shell", "implicitHeight", 100)
        defaultY: layout.stackTop(screen) + 0
        CpuWidget {
            anchors.fill: parent
            monitor: monitor
        }
    }

    MovableWidget {
        layoutManager: layout
        widgetId: "temperature"
        implicitWidth: Config.Settings.value("Coral Lagoon", "shell", "implicitWidth_2", 260)
        implicitHeight: Config.Settings.value("Coral Lagoon", "shell", "implicitHeight_2", 100)
        defaultY: layout.stackTop(screen) + 106
        TempWidget {
            anchors.fill: parent
            monitor: monitor
        }
    }

    MovableWidget {
        layoutManager: layout
        widgetId: "memory"
        implicitWidth: Config.Settings.value("Coral Lagoon", "shell", "implicitWidth_3", 260)
        implicitHeight: Config.Settings.value("Coral Lagoon", "shell", "implicitHeight_3", 100)
        defaultY: layout.stackTop(screen) + 212
        MemoryWidget {
            anchors.fill: parent
            monitor: monitor
        }
    }

    MovableWidget {
        layoutManager: layout
        widgetId: "network"
        implicitWidth: Config.Settings.value("Coral Lagoon", "shell", "implicitWidth_4", 260)
        implicitHeight: Config.Settings.value("Coral Lagoon", "shell", "implicitHeight_4", 100)
        defaultY: layout.stackTop(screen) + 318
        NetworkWidget {
            anchors.fill: parent
            monitor: monitor
        }
    }

    MediaPanel {
        layoutManager: layout
        widgetId: "media"
        defaultX: Math.max(0, screen.width - implicitWidth - 20)
        defaultY: layout.availableTop(screen) + 28
        panelColor: Config.Settings.value("Coral Lagoon", "shell", "panelColor", "#b8062b40")
        edgeColor: Config.Settings.value("Coral Lagoon", "shell", "edgeColor", "#6bbacb")
        textColor: Config.Settings.value("Coral Lagoon", "shell", "textColor", "#e5f6ff")
        accentColor: Config.Settings.value("Coral Lagoon", "shell", "accentColor", "#efb957")
        panelOpacity: Config.Settings.value("Coral Lagoon", "shell", "panelOpacity", 1.0)
        cornerRadius: Config.Settings.value("Coral Lagoon", "shell", "cornerRadius", 48)
        edgeWidth: Config.Settings.value("Coral Lagoon", "shell", "edgeWidth", 3)
    }
    PowerMenu {
        panelColor: Config.Settings.value("Coral Lagoon", "shell", "panelColor_2", "#b8062b40")
        edgeColor: Config.Settings.value("Coral Lagoon", "shell", "edgeColor_2", "#6bbacb")
        textColor: Config.Settings.value("Coral Lagoon", "shell", "textColor_2", "#e5f6ff")
        accentColor: Config.Settings.value("Coral Lagoon", "shell", "accentColor_2", "#efb957")
        panelOpacity: Config.Settings.value("Coral Lagoon", "shell", "panelOpacity_2", 1.0)
        cornerRadius: Config.Settings.value("Coral Lagoon", "shell", "cornerRadius_2", 48)
        edgeWidth: Config.Settings.value("Coral Lagoon", "shell", "edgeWidth_2", 3)
    }
    DesktopUi {
        pillVolumeControls: true
        clockTextColor: "#cfb5ef"
        barButtonRadius: 999
        launcherBubbles: true
        ringAccents: true
        launcherSymbol: Config.Settings.value("Coral Lagoon", "shell", "launcherSymbol", "ring")
        monitor: monitor
        panelColor: Config.Settings.value("Coral Lagoon", "shell", "panelColor_3", "#b8062b40")
        edgeColor: Config.Settings.value("Coral Lagoon", "shell", "edgeColor_3", "#6bbacb")
        textColor: Config.Settings.value("Coral Lagoon", "shell", "textColor_3", "#e5f6ff")
        accentColor: Config.Settings.value("Coral Lagoon", "shell", "accentColor_3", "#efb957")
        cornerRadius: Config.Settings.value("Coral Lagoon", "shell", "cornerRadius_3", 48)
        edgeWidth: Config.Settings.value("Coral Lagoon", "shell", "edgeWidth_3", 3)
    }
}
