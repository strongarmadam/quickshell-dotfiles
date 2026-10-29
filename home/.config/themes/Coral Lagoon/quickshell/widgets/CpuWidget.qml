import "." as Config
import QtQuick

Rectangle {
    property var monitor

    width: Config.Settings.value("Coral Lagoon", "CpuWidget", "width", 260)
    height: Config.Settings.value("Coral Lagoon", "CpuWidget", "height", 100)
    radius: Math.min(width, height) / 2
    color: Config.Settings.value("Coral Lagoon", "CpuWidget", "color", "#b8062b40")
    opacity: Config.Settings.value("Coral Lagoon", "CpuWidget", "opacity", 1.0)
    border.color: Config.Settings.value("Coral Lagoon", "CpuWidget", "border.color", "#6bbacb")
    border.width: Config.Settings.value("Coral Lagoon", "CpuWidget", "border.width", 3)
    Column {
        anchors.fill: parent
        anchors.margins: Config.Settings.value("Coral Lagoon", "CpuWidget", "anchors.margins", 24)
        spacing: Config.Settings.value("Coral Lagoon", "CpuWidget", "spacing", 5)
        Item {
            width: parent.width
            height: Math.max(headerLabel.implicitHeight, headerValue.implicitHeight)
            Row {
                id: headerLabel
                anchors.left: parent.left
                Text {
                    text: "  CPU"
                    color: Config.Settings.value("Coral Lagoon", "CpuWidget", "color_2", "#efb957")
                    font.family: Config.Settings.value("Coral Lagoon", "CpuWidget", "font.family", "JetBrainsMono Nerd Font")
                    font.pixelSize: Config.Settings.value("Coral Lagoon", "CpuWidget", "font.pixelSize", 12)
                    font.bold: true
                }
            }

            Text {
                id: headerValue
                anchors.right: parent.right
                text: monitor.cpuUsage.toFixed(0) + "%"
                color: Config.Settings.value("Coral Lagoon", "CpuWidget", "color_3", "#e5f6ff")
                font.pixelSize: Config.Settings.value("Coral Lagoon", "CpuWidget", "font.pixelSize_2", 13)
                font.bold: true
            }
        }

        Graph {
            width: parent.width
            height: Config.Settings.value("Coral Lagoon", "CpuWidget", "height_3", 48)
            values: monitor.cpuHistory
            minimum: 0
            maximum: 100
        }
    }
}
