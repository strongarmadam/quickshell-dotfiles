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
        implicitWidth: Config.Settings.value("Bakery Hearth", "shell", "implicitWidth", 260)
        implicitHeight: Config.Settings.value("Bakery Hearth", "shell", "implicitHeight", 100)
        defaultY: layout.stackTop(screen) + 0
        CpuWidget {
            anchors.fill: parent
            monitor: monitor
        }
    }

    MovableWidget {
        layoutManager: layout
        widgetId: "temperature"
        implicitWidth: Config.Settings.value("Bakery Hearth", "shell", "implicitWidth_2", 260)
        implicitHeight: Config.Settings.value("Bakery Hearth", "shell", "implicitHeight_2", 100)
        defaultY: layout.stackTop(screen) + 106
        TempWidget {
            anchors.fill: parent
            monitor: monitor
        }
    }

    MovableWidget {
        layoutManager: layout
        widgetId: "memory"
        implicitWidth: Config.Settings.value("Bakery Hearth", "shell", "implicitWidth_3", 260)
        implicitHeight: Config.Settings.value("Bakery Hearth", "shell", "implicitHeight_3", 100)
        defaultY: layout.stackTop(screen) + 212
        MemoryWidget {
            anchors.fill: parent
            monitor: monitor
        }
    }

    MovableWidget {
        layoutManager: layout
        widgetId: "network"
        implicitWidth: Config.Settings.value("Bakery Hearth", "shell", "implicitWidth_4", 260)
        implicitHeight: Config.Settings.value("Bakery Hearth", "shell", "implicitHeight_4", 100)
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
        panelColor: Config.Settings.value("Bakery Hearth", "shell", "panelColor", "#dc5a3e2e")
        edgeColor: Config.Settings.value("Bakery Hearth", "shell", "edgeColor", "#b58c6b")
        textColor: Config.Settings.value("Bakery Hearth", "shell", "textColor", "#fce3c1")
        accentColor: Config.Settings.value("Bakery Hearth", "shell", "accentColor", "#dfb88e")
        panelOpacity: Config.Settings.value("Bakery Hearth", "shell", "panelOpacity", 1.0)
        cornerRadius: Config.Settings.value("Bakery Hearth", "shell", "cornerRadius", 4)
        edgeWidth: Config.Settings.value("Bakery Hearth", "shell", "edgeWidth", 1)
    }
    PowerMenu {
        panelColor: Config.Settings.value("Bakery Hearth", "shell", "panelColor_2", "#dc5a3e2e")
        edgeColor: Config.Settings.value("Bakery Hearth", "shell", "edgeColor_2", "#b58c6b")
        textColor: Config.Settings.value("Bakery Hearth", "shell", "textColor_2", "#fce3c1")
        accentColor: Config.Settings.value("Bakery Hearth", "shell", "accentColor_2", "#dfb88e")
        panelOpacity: Config.Settings.value("Bakery Hearth", "shell", "panelOpacity_2", 1.0)
        cornerRadius: Config.Settings.value("Bakery Hearth", "shell", "cornerRadius_2", 4)
        edgeWidth: Config.Settings.value("Bakery Hearth", "shell", "edgeWidth_2", 1)
    }
    DesktopUi {
        launcherSymbol: Config.Settings.value("Bakery Hearth", "shell", "launcherSymbol", "bar")
        monitor: monitor
        panelColor: Config.Settings.value("Bakery Hearth", "shell", "panelColor_3", "#dc5a3e2e")
        edgeColor: Config.Settings.value("Bakery Hearth", "shell", "edgeColor_3", "#b58c6b")
        textColor: Config.Settings.value("Bakery Hearth", "shell", "textColor_3", "#fce3c1")
        accentColor: Config.Settings.value("Bakery Hearth", "shell", "accentColor_3", "#dfb88e")
        cornerRadius: Config.Settings.value("Bakery Hearth", "shell", "cornerRadius_3", 4)
        edgeWidth: Config.Settings.value("Bakery Hearth", "shell", "edgeWidth_3", 1)
    }
}
