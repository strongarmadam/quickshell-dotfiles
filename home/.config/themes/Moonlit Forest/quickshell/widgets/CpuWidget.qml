import "." as Config
import QtQuick

Rectangle {
    property var monitor

    width: Config.Settings.value("Moonlit Forest", "CpuWidget", "width", 260)
    height: Config.Settings.value("Moonlit Forest", "CpuWidget", "height", 100)
    radius: Config.Settings.value("Moonlit Forest", "CpuWidget", "radius", 0)
    color: Config.Settings.value("Moonlit Forest", "CpuWidget", "color", "#b8030609")
    opacity: Config.Settings.value("Moonlit Forest", "CpuWidget", "opacity", 1.0)
    border.color: Config.Settings.value("Moonlit Forest", "CpuWidget", "border.color", "#155779")
    border.width: Config.Settings.value("Moonlit Forest", "CpuWidget", "border.width", 3)
    Column {
        anchors.fill: parent
        anchors.margins: Config.Settings.value("Moonlit Forest", "CpuWidget", "anchors.margins", 14)
        spacing: Config.Settings.value("Moonlit Forest", "CpuWidget", "spacing", 5)
        Row {
            width: parent.width

            Text {
                text: "  CPU"
                color: Config.Settings.value("Moonlit Forest", "CpuWidget", "color_2", "#3aa9d2")
                font.family: Config.Settings.value("Moonlit Forest", "CpuWidget", "font.family", "JetBrainsMono Nerd Font")
                font.pixelSize: Config.Settings.value("Moonlit Forest", "CpuWidget", "font.pixelSize", 12)
                font.bold: true
            }

            Item {
                width: parent.width - 95
                height: Config.Settings.value("Moonlit Forest", "CpuWidget", "height_2", 1)
            }

            Text {
                text: monitor.cpuUsage.toFixed(0) + "%"
                color: Config.Settings.value("Moonlit Forest", "CpuWidget", "color_3", "#3aa9d2")
                font.pixelSize: Config.Settings.value("Moonlit Forest", "CpuWidget", "font.pixelSize_2", 13)
                font.bold: true
            }
        }

        Graph {
            width: parent.width
            height: Config.Settings.value("Moonlit Forest", "CpuWidget", "height_3", 48)
            values: monitor.cpuHistory
            minimum: 0
            maximum: 100
        }
    }
}
