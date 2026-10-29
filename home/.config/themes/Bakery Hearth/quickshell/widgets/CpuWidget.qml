import "." as Config
import QtQuick

Rectangle {
    id: root

    property var monitor

    width: Config.Settings.value("Bakery Hearth", "CpuWidget", "width", 260)
    height: Config.Settings.value("Bakery Hearth", "CpuWidget", "height", 100)
    radius: Config.Settings.value("Bakery Hearth", "CpuWidget", "radius", 4)
    color: Config.Settings.value("Bakery Hearth", "CpuWidget", "color", "#dc5a3e2e")
    opacity: Config.Settings.value("Bakery Hearth", "CpuWidget", "opacity", 1.0)
    border.color: Config.Settings.value("Bakery Hearth", "CpuWidget", "border.color", "#b58c6b")
    border.width: Config.Settings.value("Bakery Hearth", "CpuWidget", "border.width", 1)
    Column {
        anchors.fill: parent
        anchors.margins: Config.Settings.value("Bakery Hearth", "CpuWidget", "anchors.margins", 14)
        spacing: Config.Settings.value("Bakery Hearth", "CpuWidget", "spacing", 5)
        Item {
            width: parent.width
            height: Math.max(headerLabel.implicitHeight, headerValue.implicitHeight)
            Row {
                id: headerLabel
                anchors.left: parent.left
                Text {
                    text: "  CPU"
                    color: Config.Settings.value("Bakery Hearth", "CpuWidget", "color_2", "#dfb88e")
                    font.family: Config.Settings.value("Bakery Hearth", "CpuWidget", "font.family", "JetBrainsMono Nerd Font")
                    font.pixelSize: Config.Settings.value("Bakery Hearth", "CpuWidget", "font.pixelSize", 12)
                    font.bold: true
                }
            }

            Text {
                id: headerValue
                anchors.right: parent.right
                text: monitor.cpuUsage.toFixed(0) + "%"
                color: Config.Settings.value("Bakery Hearth", "CpuWidget", "color_3", "#fce3c1")
                font.pixelSize: Config.Settings.value("Bakery Hearth", "CpuWidget", "font.pixelSize_2", 13)
                font.bold: true
            }
        }

        Graph {
            width: parent.width
            height: Config.Settings.value("Bakery Hearth", "CpuWidget", "height_3", 48)
            values: monitor.cpuHistory
            minimum: 0
            maximum: 100
        }
    }
}
