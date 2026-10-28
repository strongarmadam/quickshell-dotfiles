import "." as Config
import QtQuick

Rectangle {
    id: root

    property var monitor

    width: Config.Settings.value("Autumn Grove", "CpuWidget", "width", 260)
    height: Config.Settings.value("Autumn Grove", "CpuWidget", "height", 100)
    radius: Config.Settings.value("Autumn Grove", "CpuWidget", "radius", 18)
    color: Config.Settings.value("Autumn Grove", "CpuWidget", "color", "#241b16")
    opacity: Config.Settings.value("Autumn Grove", "CpuWidget", "opacity", 0.70)
    border.color: Config.Settings.value("Autumn Grove", "CpuWidget", "border.color", "#a89270")
    border.width: Config.Settings.value("Autumn Grove", "CpuWidget", "border.width", 1)
    Column {
        anchors.fill: parent
        anchors.margins: Config.Settings.value("Autumn Grove", "CpuWidget", "anchors.margins", 14)
        spacing: Config.Settings.value("Autumn Grove", "CpuWidget", "spacing", 5)
        Row {
            width: parent.width

            Text {
                text: "  CPU"
                color: Config.Settings.value("Autumn Grove", "CpuWidget", "color_2", "#c59b62")
                font.family: Config.Settings.value("Autumn Grove", "CpuWidget", "font.family", "JetBrainsMono Nerd Font")
                font.pixelSize: Config.Settings.value("Autumn Grove", "CpuWidget", "font.pixelSize", 12)
                font.bold: true
            }

            Item {
                width: parent.width - 95
                height: Config.Settings.value("Autumn Grove", "CpuWidget", "height_2", 1)
            }

            Text {
                text: monitor.cpuUsage.toFixed(0) + "%"
                color: Config.Settings.value("Autumn Grove", "CpuWidget", "color_3", "#e5d8bd")
                font.pixelSize: Config.Settings.value("Autumn Grove", "CpuWidget", "font.pixelSize_2", 13)
                font.bold: true
            }
        }

        Graph {
            width: parent.width
            height: Config.Settings.value("Autumn Grove", "CpuWidget", "height_3", 48)
            values: monitor.cpuHistory
            minimum: 0
            maximum: 100
        }
    }
}
