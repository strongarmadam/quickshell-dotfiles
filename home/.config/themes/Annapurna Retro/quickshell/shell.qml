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
        implicitWidth: Config.Settings.value("Annapurna Retro", "shell", "implicitWidth", 260)
        implicitHeight: Config.Settings.value("Annapurna Retro", "shell", "implicitHeight", 100)
        defaultY: layout.stackTop(screen) + 0
        CpuWidget {
            anchors.fill: parent
            monitor: monitor
        }
    }

    MovableWidget {
        layoutManager: layout
        widgetId: "temperature"
        implicitWidth: Config.Settings.value("Annapurna Retro", "shell", "implicitWidth_2", 260)
        implicitHeight: Config.Settings.value("Annapurna Retro", "shell", "implicitHeight_2", 100)
        defaultY: layout.stackTop(screen) + 106
        TempWidget {
            anchors.fill: parent
            monitor: monitor
        }
    }

    MovableWidget {
        layoutManager: layout
        widgetId: "memory"
        implicitWidth: Config.Settings.value("Annapurna Retro", "shell", "implicitWidth_3", 260)
        implicitHeight: Config.Settings.value("Annapurna Retro", "shell", "implicitHeight_3", 100)
        defaultY: layout.stackTop(screen) + 212
        MemoryWidget {
            anchors.fill: parent
            monitor: monitor
        }
    }

    MovableWidget {
        layoutManager: layout
        widgetId: "network"
        implicitWidth: Config.Settings.value("Annapurna Retro", "shell", "implicitWidth_4", 260)
        implicitHeight: Config.Settings.value("Annapurna Retro", "shell", "implicitHeight_4", 100)
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
        panelColor: Config.Settings.value("Annapurna Retro", "shell", "panelColor", "#b810354d")
        edgeColor: Config.Settings.value("Annapurna Retro", "shell", "edgeColor", "#ffffff")
        textColor: Config.Settings.value("Annapurna Retro", "shell", "textColor", "#f1faff")
        accentColor: Config.Settings.value("Annapurna Retro", "shell", "accentColor", "#45b8ff")
        panelOpacity: Config.Settings.value("Annapurna Retro", "shell", "panelOpacity", 1.0)
        cornerRadius: Config.Settings.value("Annapurna Retro", "shell", "cornerRadius", 0)
        edgeWidth: Config.Settings.value("Annapurna Retro", "shell", "edgeWidth", 3)
    }
    PowerMenu {
        panelColor: Config.Settings.value("Annapurna Retro", "shell", "panelColor_2", "#b810354d")
        edgeColor: Config.Settings.value("Annapurna Retro", "shell", "edgeColor_2", "#ffffff")
        textColor: Config.Settings.value("Annapurna Retro", "shell", "textColor_2", "#f1faff")
        accentColor: Config.Settings.value("Annapurna Retro", "shell", "accentColor_2", "#45b8ff")
        panelOpacity: Config.Settings.value("Annapurna Retro", "shell", "panelOpacity_2", 1.0)
        cornerRadius: Config.Settings.value("Annapurna Retro", "shell", "cornerRadius_2", 0)
        edgeWidth: Config.Settings.value("Annapurna Retro", "shell", "edgeWidth_2", 3)
    }
    DesktopUi {
        clockTextColor: "#ffffff"
        launcherSymbol: Config.Settings.value("Annapurna Retro", "shell", "launcherSymbol", "triangle")
        monitor: monitor
        panelColor: Config.Settings.value("Annapurna Retro", "shell", "panelColor_3", "#b810354d")
        edgeColor: Config.Settings.value("Annapurna Retro", "shell", "edgeColor_3", "#ffffff")
        textColor: Config.Settings.value("Annapurna Retro", "shell", "textColor_3", "#f1faff")
        accentColor: Config.Settings.value("Annapurna Retro", "shell", "accentColor_3", "#45b8ff")
        cornerRadius: Config.Settings.value("Annapurna Retro", "shell", "cornerRadius_3", 0)
        edgeWidth: Config.Settings.value("Annapurna Retro", "shell", "edgeWidth_3", 3)
    }
}
