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
        implicitWidth: Config.Settings.value("16-bit Sunset", "shell", "implicitWidth", 260)
        implicitHeight: Config.Settings.value("16-bit Sunset", "shell", "implicitHeight", 100)
        defaultY: layout.stackTop(screen) + 0
        CpuWidget {
            anchors.fill: parent
            monitor: monitor
        }
    }

    MovableWidget {
        layoutManager: layout
        widgetId: "temperature"
        implicitWidth: Config.Settings.value("16-bit Sunset", "shell", "implicitWidth_2", 260)
        implicitHeight: Config.Settings.value("16-bit Sunset", "shell", "implicitHeight_2", 100)
        defaultY: layout.stackTop(screen) + 106
        TempWidget {
            anchors.fill: parent
            monitor: monitor
        }
    }

    MovableWidget {
        layoutManager: layout
        widgetId: "memory"
        implicitWidth: Config.Settings.value("16-bit Sunset", "shell", "implicitWidth_3", 260)
        implicitHeight: Config.Settings.value("16-bit Sunset", "shell", "implicitHeight_3", 100)
        defaultY: layout.stackTop(screen) + 212
        MemoryWidget {
            anchors.fill: parent
            monitor: monitor
        }
    }

    MovableWidget {
        layoutManager: layout
        widgetId: "network"
        implicitWidth: Config.Settings.value("16-bit Sunset", "shell", "implicitWidth_4", 260)
        implicitHeight: Config.Settings.value("16-bit Sunset", "shell", "implicitHeight_4", 100)
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
        panelColor: Config.Settings.value("16-bit Sunset", "shell", "panelColor", "#b8292447")
        edgeColor: Config.Settings.value("16-bit Sunset", "shell", "edgeColor", "#51406b")
        textColor: Config.Settings.value("16-bit Sunset", "shell", "textColor", "#d47755")
        accentColor: Config.Settings.value("16-bit Sunset", "shell", "accentColor", "#d47755")
        panelOpacity: Config.Settings.value("16-bit Sunset", "shell", "panelOpacity", 1.0)
        cornerRadius: Config.Settings.value("16-bit Sunset", "shell", "cornerRadius", 0)
        edgeWidth: Config.Settings.value("16-bit Sunset", "shell", "edgeWidth", 3)
    }
    PowerMenu {
        panelColor: Config.Settings.value("16-bit Sunset", "shell", "panelColor_2", "#b8292447")
        edgeColor: Config.Settings.value("16-bit Sunset", "shell", "edgeColor_2", "#51406b")
        textColor: Config.Settings.value("16-bit Sunset", "shell", "textColor_2", "#d47755")
        accentColor: Config.Settings.value("16-bit Sunset", "shell", "accentColor_2", "#d47755")
        panelOpacity: Config.Settings.value("16-bit Sunset", "shell", "panelOpacity_2", 1.0)
        cornerRadius: Config.Settings.value("16-bit Sunset", "shell", "cornerRadius_2", 0)
        edgeWidth: Config.Settings.value("16-bit Sunset", "shell", "edgeWidth_2", 3)
    }
    DesktopUi {
        launcherSymbol: Config.Settings.value("16-bit Sunset", "shell", "launcherSymbol", "square")
        monitor: monitor
        panelColor: Config.Settings.value("16-bit Sunset", "shell", "panelColor_3", "#b8292447")
        edgeColor: Config.Settings.value("16-bit Sunset", "shell", "edgeColor_3", "#51406b")
        textColor: Config.Settings.value("16-bit Sunset", "shell", "textColor_3", "#f4dfb4")
        accentColor: Config.Settings.value("16-bit Sunset", "shell", "accentColor_3", "#d47755")
        cornerRadius: Config.Settings.value("16-bit Sunset", "shell", "cornerRadius_3", 0)
        edgeWidth: Config.Settings.value("16-bit Sunset", "shell", "edgeWidth_3", 3)
    }
}
