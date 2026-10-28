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
        implicitWidth: Config.Settings.value("Rivendell", "shell", "implicitWidth", 260)
        implicitHeight: Config.Settings.value("Rivendell", "shell", "implicitHeight", 100)
        defaultY: layout.stackTop(screen) + 0
        CpuWidget {
            anchors.fill: parent
            monitor: monitor
        }
    }

    MovableWidget {
        layoutManager: layout
        widgetId: "temperature"
        implicitWidth: Config.Settings.value("Rivendell", "shell", "implicitWidth_2", 260)
        implicitHeight: Config.Settings.value("Rivendell", "shell", "implicitHeight_2", 100)
        defaultY: layout.stackTop(screen) + 106
        TempWidget {
            anchors.fill: parent
            monitor: monitor
        }
    }

    MovableWidget {
        layoutManager: layout
        widgetId: "memory"
        implicitWidth: Config.Settings.value("Rivendell", "shell", "implicitWidth_3", 260)
        implicitHeight: Config.Settings.value("Rivendell", "shell", "implicitHeight_3", 100)
        defaultY: layout.stackTop(screen) + 212
        MemoryWidget {
            anchors.fill: parent
            monitor: monitor
        }
    }

    MovableWidget {
        layoutManager: layout
        widgetId: "network"
        implicitWidth: Config.Settings.value("Rivendell", "shell", "implicitWidth_4", 260)
        implicitHeight: Config.Settings.value("Rivendell", "shell", "implicitHeight_4", 100)
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
        panelColor: Config.Settings.value("Rivendell", "shell", "panelColor", "#1e241c")
        edgeColor: Config.Settings.value("Rivendell", "shell", "edgeColor", "#76674b")
        textColor: Config.Settings.value("Rivendell", "shell", "textColor", "#e2dcc5")
        accentColor: Config.Settings.value("Rivendell", "shell", "accentColor", "#aa8953")
        panelOpacity: Config.Settings.value("Rivendell", "shell", "panelOpacity", 0.70)
        cornerRadius: Config.Settings.value("Rivendell", "shell", "cornerRadius", 18)
        edgeWidth: Config.Settings.value("Rivendell", "shell", "edgeWidth", 1)
    }
    PowerMenu {
        panelColor: Config.Settings.value("Rivendell", "shell", "panelColor_2", "#1e241c")
        edgeColor: Config.Settings.value("Rivendell", "shell", "edgeColor_2", "#76674b")
        textColor: Config.Settings.value("Rivendell", "shell", "textColor_2", "#e2dcc5")
        accentColor: Config.Settings.value("Rivendell", "shell", "accentColor_2", "#aa8953")
        panelOpacity: Config.Settings.value("Rivendell", "shell", "panelOpacity_2", 0.70)
        cornerRadius: Config.Settings.value("Rivendell", "shell", "cornerRadius_2", 18)
        edgeWidth: Config.Settings.value("Rivendell", "shell", "edgeWidth_2", 1)
    }
    DesktopUi {
        launcherSymbol: Config.Settings.value("Rivendell", "shell", "launcherSymbol", "ring")
        launcherBubbles: Config.Settings.value("Rivendell", "shell", "launcherBubbles", true)
        ringAccents: Config.Settings.value("Rivendell", "shell", "ringAccents", true)
        clockTextColor: Config.Settings.value("Rivendell", "shell", "clockTextColor", "#f1e8ce")
        clockBackground: Config.Settings.value("Rivendell", "shell", "clockBackground", "#c21e241c")
        barBackground: Config.Settings.value("Rivendell", "shell", "barBackground", "transparent")
        monitor: monitor
        panelColor: Config.Settings.value("Rivendell", "shell", "panelColor_3", "#1e241c")
        edgeColor: Config.Settings.value("Rivendell", "shell", "edgeColor_3", "#76674b")
        textColor: Config.Settings.value("Rivendell", "shell", "textColor_3", "#e2dcc5")
        accentColor: Config.Settings.value("Rivendell", "shell", "accentColor_3", "#aa8953")
        panelOpacity: Config.Settings.value("Rivendell", "shell", "panelOpacity_3", 0.70)
        cornerRadius: Config.Settings.value("Rivendell", "shell", "cornerRadius_3", 18)
        edgeWidth: Config.Settings.value("Rivendell", "shell", "edgeWidth_3", 1)
    }
}
