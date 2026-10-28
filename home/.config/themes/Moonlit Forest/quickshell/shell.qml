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
        implicitWidth: Config.Settings.value("Moonlit Forest", "shell", "implicitWidth", 260)
        implicitHeight: Config.Settings.value("Moonlit Forest", "shell", "implicitHeight", 100)
        defaultY: layout.stackTop(screen) + 0
        CpuWidget {
            anchors.fill: parent
            monitor: monitor
        }
    }

    MovableWidget {
        layoutManager: layout
        widgetId: "temperature"
        implicitWidth: Config.Settings.value("Moonlit Forest", "shell", "implicitWidth_2", 260)
        implicitHeight: Config.Settings.value("Moonlit Forest", "shell", "implicitHeight_2", 100)
        defaultY: layout.stackTop(screen) + 106
        TempWidget {
            anchors.fill: parent
            monitor: monitor
        }
    }

    MovableWidget {
        layoutManager: layout
        widgetId: "memory"
        implicitWidth: Config.Settings.value("Moonlit Forest", "shell", "implicitWidth_3", 260)
        implicitHeight: Config.Settings.value("Moonlit Forest", "shell", "implicitHeight_3", 100)
        defaultY: layout.stackTop(screen) + 212
        MemoryWidget {
            anchors.fill: parent
            monitor: monitor
        }
    }

    MovableWidget {
        layoutManager: layout
        widgetId: "network"
        implicitWidth: Config.Settings.value("Moonlit Forest", "shell", "implicitWidth_4", 260)
        implicitHeight: Config.Settings.value("Moonlit Forest", "shell", "implicitHeight_4", 100)
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
        panelColor: Config.Settings.value("Moonlit Forest", "shell", "panelColor", "#b8030609")
        edgeColor: Config.Settings.value("Moonlit Forest", "shell", "edgeColor", "#155779")
        textColor: Config.Settings.value("Moonlit Forest", "shell", "textColor", "#3aa9d2")
        accentColor: Config.Settings.value("Moonlit Forest", "shell", "accentColor", "#3aa9d2")
        panelOpacity: Config.Settings.value("Moonlit Forest", "shell", "panelOpacity", 1.0)
        cornerRadius: Config.Settings.value("Moonlit Forest", "shell", "cornerRadius", 0)
        edgeWidth: Config.Settings.value("Moonlit Forest", "shell", "edgeWidth", 3)
    }
    PowerMenu {
        panelColor: Config.Settings.value("Moonlit Forest", "shell", "panelColor_2", "#b8030609")
        edgeColor: Config.Settings.value("Moonlit Forest", "shell", "edgeColor_2", "#155779")
        textColor: Config.Settings.value("Moonlit Forest", "shell", "textColor_2", "#3aa9d2")
        accentColor: Config.Settings.value("Moonlit Forest", "shell", "accentColor_2", "#3aa9d2")
        panelOpacity: Config.Settings.value("Moonlit Forest", "shell", "panelOpacity_2", 1.0)
        cornerRadius: Config.Settings.value("Moonlit Forest", "shell", "cornerRadius_2", 0)
        edgeWidth: Config.Settings.value("Moonlit Forest", "shell", "edgeWidth_2", 3)
    }
    DesktopUi {
        clockTextColor: "#ffffff"
        barButtonRadius: 4
        launcherSymbol: Config.Settings.value("Moonlit Forest", "shell", "launcherSymbol", "square")
        monitor: monitor
        panelColor: Config.Settings.value("Moonlit Forest", "shell", "panelColor_3", "#b8030609")
        edgeColor: Config.Settings.value("Moonlit Forest", "shell", "edgeColor_3", "#155779")
        textColor: Config.Settings.value("Moonlit Forest", "shell", "textColor_3", "#d7f3ff")
        accentColor: Config.Settings.value("Moonlit Forest", "shell", "accentColor_3", "#3aa9d2")
        cornerRadius: Config.Settings.value("Moonlit Forest", "shell", "cornerRadius_3", 0)
        edgeWidth: Config.Settings.value("Moonlit Forest", "shell", "edgeWidth_3", 3)
    }
}
