import "." as Config
import QtQuick

Rectangle {
    id: root

    property var monitor

    width: Config.Settings.value("Space Green", "CpuWidget", "width", 260)
    height: Config.Settings.value("Space Green", "CpuWidget", "height", 100)
    radius: Config.Settings.value("Space Green", "CpuWidget", "radius", 18)
    color: Config.Settings.value("Space Green", "CpuWidget", "color", "#0c1f18")
    opacity: Config.Settings.value("Space Green", "CpuWidget", "opacity", 0.72)
    border.color: Config.Settings.value("Space Green", "CpuWidget", "border.color", "#436b57")
    border.width: Config.Settings.value("Space Green", "CpuWidget", "border.width", 1)
    Column {
        anchors.fill: parent
        anchors.margins: Config.Settings.value("Space Green", "CpuWidget", "anchors.margins", 14)
        spacing: Config.Settings.value("Space Green", "CpuWidget", "spacing", 5)
        Row {
            width: parent.width

            Text {
                text: "  CPU"
                color: Config.Settings.value("Space Green", "CpuWidget", "color_2", "#f4b942")
                font.family: Config.Settings.value("Space Green", "CpuWidget", "font.family", "JetBrainsMono Nerd Font")
                font.pixelSize: Config.Settings.value("Space Green", "CpuWidget", "font.pixelSize", 12)
                font.bold: true
            }

            Item {
                width: parent.width - 95
                height: Config.Settings.value("Space Green", "CpuWidget", "height_2", 1)
            }

            Text {
                text: monitor.cpuUsage.toFixed(0) + "%"
                color: Config.Settings.value("Space Green", "CpuWidget", "color_3", "#d7e5dc")
                font.pixelSize: Config.Settings.value("Space Green", "CpuWidget", "font.pixelSize_2", 13)
                font.bold: true
            }
        }

        Graph {
            width: parent.width
            height: Config.Settings.value("Space Green", "CpuWidget", "height_3", 48)
            values: monitor.cpuHistory
            minimum: 0
            maximum: 100
        }
    }
}
