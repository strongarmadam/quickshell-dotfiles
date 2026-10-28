//@ pragma IconTheme Adwaita
import "./widgets" as Config
import "./widgets"
import Quickshell
import QtQuick

ShellRoot {
    id: root
    WorkspacePan {}
    SystemMonitor { id: monitor }
    WidgetLayout { id: layout }

    MovableWidget {
        layoutManager: layout
        widgetId: "cpu"
        implicitWidth: Config.Settings.value("Autumn Grove", "shell", "implicitWidth", 260)
        implicitHeight: Config.Settings.value("Autumn Grove", "shell", "implicitHeight", 100)
        defaultY: layout.stackTop(screen) + 0
        CpuWidget {
            anchors.fill: parent
            monitor: monitor
        }
    }

    MovableWidget {
        layoutManager: layout
        widgetId: "temperature"
        implicitWidth: Config.Settings.value("Autumn Grove", "shell", "implicitWidth_2", 260)
        implicitHeight: Config.Settings.value("Autumn Grove", "shell", "implicitHeight_2", 100)
        defaultY: layout.stackTop(screen) + 106
        TempWidget {
            anchors.fill: parent
            monitor: monitor
        }
    }

    MovableWidget {
        layoutManager: layout
        widgetId: "memory"
        implicitWidth: Config.Settings.value("Autumn Grove", "shell", "implicitWidth_3", 260)
        implicitHeight: Config.Settings.value("Autumn Grove", "shell", "implicitHeight_3", 100)
        defaultY: layout.stackTop(screen) + 212
        MemoryWidget {
            anchors.fill: parent
            monitor: monitor
        }
    }

    MovableWidget {
        layoutManager: layout
        widgetId: "network"
        implicitWidth: Config.Settings.value("Autumn Grove", "shell", "implicitWidth_4", 260)
        implicitHeight: Config.Settings.value("Autumn Grove", "shell", "implicitHeight_4", 100)
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
        panelColor: Config.Settings.value("Autumn Grove", "shell", "panelColor", "#241b16")
        edgeColor: Config.Settings.value("Autumn Grove", "shell", "edgeColor", "#a89270")
        textColor: Config.Settings.value("Autumn Grove", "shell", "textColor", "#e5d8bd")
        accentColor: Config.Settings.value("Autumn Grove", "shell", "accentColor", "#c59b62")
        panelOpacity: Config.Settings.value("Autumn Grove", "shell", "panelOpacity", 0.70)
        cornerRadius: Config.Settings.value("Autumn Grove", "shell", "cornerRadius", 18)
        edgeWidth: Config.Settings.value("Autumn Grove", "shell", "edgeWidth", 1)
    }
    PowerMenu {
        panelColor: Config.Settings.value("Autumn Grove", "shell", "panelColor_2", "#241b16")
        edgeColor: Config.Settings.value("Autumn Grove", "shell", "edgeColor_2", "#a89270")
        textColor: Config.Settings.value("Autumn Grove", "shell", "textColor_2", "#e5d8bd")
        accentColor: Config.Settings.value("Autumn Grove", "shell", "accentColor_2", "#c59b62")
        panelOpacity: Config.Settings.value("Autumn Grove", "shell", "panelOpacity_2", 0.70)
        cornerRadius: Config.Settings.value("Autumn Grove", "shell", "cornerRadius_2", 18)
        edgeWidth: Config.Settings.value("Autumn Grove", "shell", "edgeWidth_2", 1)
    }
    DesktopUi {
        launcherSymbol: Config.Settings.value("Autumn Grove", "shell", "launcherSymbol", "diamond")
        launcherBubbles: Config.Settings.value("Autumn Grove", "shell", "launcherBubbles", true)
        barBackground: "transparent"
        monitor: monitor
        panelColor: Config.Settings.value("Autumn Grove", "shell", "panelColor_3", "#241b16")
        edgeColor: Config.Settings.value("Autumn Grove", "shell", "edgeColor_3", "#a89270")
        textColor: Config.Settings.value("Autumn Grove", "shell", "textColor_3", "#e5d8bd")
        accentColor: Config.Settings.value("Autumn Grove", "shell", "accentColor_3", "#c59b62")
        panelOpacity: Config.Settings.value("Autumn Grove", "shell", "panelOpacity_3", 0.70)
        cornerRadius: Config.Settings.value("Autumn Grove", "shell", "cornerRadius_3", 18)
        edgeWidth: Config.Settings.value("Autumn Grove", "shell", "edgeWidth_3", 1)
    }
}
