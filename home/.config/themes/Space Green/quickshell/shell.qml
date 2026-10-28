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
        implicitWidth: Config.Settings.value("Space Green", "shell", "implicitWidth", 260)
        implicitHeight: Config.Settings.value("Space Green", "shell", "implicitHeight", 100)
        defaultY: layout.stackTop(screen) + 0
        CpuWidget {
            anchors.fill: parent
            monitor: monitor
        }
    }

    MovableWidget {
        layoutManager: layout
        widgetId: "temperature"
        implicitWidth: Config.Settings.value("Space Green", "shell", "implicitWidth_2", 260)
        implicitHeight: Config.Settings.value("Space Green", "shell", "implicitHeight_2", 100)
        defaultY: layout.stackTop(screen) + 106
        TempWidget {
            anchors.fill: parent
            monitor: monitor
        }
    }

    MovableWidget {
        layoutManager: layout
        widgetId: "memory"
        implicitWidth: Config.Settings.value("Space Green", "shell", "implicitWidth_3", 260)
        implicitHeight: Config.Settings.value("Space Green", "shell", "implicitHeight_3", 100)
        defaultY: layout.stackTop(screen) + 212
        MemoryWidget {
            anchors.fill: parent
            monitor: monitor
        }
    }

    MovableWidget {
        layoutManager: layout
        widgetId: "network"
        implicitWidth: Config.Settings.value("Space Green", "shell", "implicitWidth_4", 260)
        implicitHeight: Config.Settings.value("Space Green", "shell", "implicitHeight_4", 100)
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
        panelColor: Config.Settings.value("Space Green", "shell", "panelColor", "#0c1f18")
        edgeColor: Config.Settings.value("Space Green", "shell", "edgeColor", "#436b57")
        textColor: Config.Settings.value("Space Green", "shell", "textColor", "#d7e5dc")
        accentColor: Config.Settings.value("Space Green", "shell", "accentColor", "#f4b942")
        panelOpacity: Config.Settings.value("Space Green", "shell", "panelOpacity", 0.72)
        cornerRadius: Config.Settings.value("Space Green", "shell", "cornerRadius", 18)
        edgeWidth: Config.Settings.value("Space Green", "shell", "edgeWidth", 1)
    }
    PowerMenu {
        panelColor: Config.Settings.value("Space Green", "shell", "panelColor_2", "#0c1f18")
        edgeColor: Config.Settings.value("Space Green", "shell", "edgeColor_2", "#436b57")
        textColor: Config.Settings.value("Space Green", "shell", "textColor_2", "#d7e5dc")
        accentColor: Config.Settings.value("Space Green", "shell", "accentColor_2", "#f4b942")
        panelOpacity: Config.Settings.value("Space Green", "shell", "panelOpacity_2", 0.72)
        cornerRadius: Config.Settings.value("Space Green", "shell", "cornerRadius_2", 18)
        edgeWidth: Config.Settings.value("Space Green", "shell", "edgeWidth_2", 1)
    }
    DesktopUi {
        launcherSymbol: Config.Settings.value("Space Green", "shell", "launcherSymbol", "circle")
        monitor: monitor
        panelColor: Config.Settings.value("Space Green", "shell", "panelColor_3", "#0c1f18")
        edgeColor: Config.Settings.value("Space Green", "shell", "edgeColor_3", "#436b57")
        textColor: Config.Settings.value("Space Green", "shell", "textColor_3", "#d7e5dc")
        accentColor: Config.Settings.value("Space Green", "shell", "accentColor_3", "#f4b942")
        panelOpacity: Config.Settings.value("Space Green", "shell", "panelOpacity_3", 0.72)
        cornerRadius: Config.Settings.value("Space Green", "shell", "cornerRadius_3", 18)
        edgeWidth: Config.Settings.value("Space Green", "shell", "edgeWidth_3", 1)
    }
}
