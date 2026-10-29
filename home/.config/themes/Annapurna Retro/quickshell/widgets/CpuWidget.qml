import "." as Config
import QtQuick

Rectangle {
    property var monitor

    width: Config.Settings.value("Annapurna Retro", "CpuWidget", "width", 260)
    height: Config.Settings.value("Annapurna Retro", "CpuWidget", "height", 100)
    radius: Config.Settings.value("Annapurna Retro", "CpuWidget", "radius", 0)
    color: Config.Settings.value("Annapurna Retro", "CpuWidget", "color", "#b810354d")
    opacity: Config.Settings.value("Annapurna Retro", "CpuWidget", "opacity", 1.0)
    border.color: Config.Settings.value("Annapurna Retro", "CpuWidget", "border.color", "#ffffff")
    border.width: Config.Settings.value("Annapurna Retro", "CpuWidget", "border.width", 3)
    Column {
        anchors.fill: parent
        anchors.margins: Config.Settings.value("Annapurna Retro", "CpuWidget", "anchors.margins", 14)
        spacing: Config.Settings.value("Annapurna Retro", "CpuWidget", "spacing", 5)
        Item {
            width: parent.width
            height: Math.max(headerLabel.implicitHeight, headerValue.implicitHeight)
            Row {
                id: headerLabel
                anchors.left: parent.left
                Text {
                    text: "  CPU"
                    color: Config.Settings.value("Annapurna Retro", "CpuWidget", "color_2", "#45b8ff")
                    font.family: Config.Settings.value("Annapurna Retro", "CpuWidget", "font.family", "JetBrainsMono Nerd Font")
                    font.pixelSize: Config.Settings.value("Annapurna Retro", "CpuWidget", "font.pixelSize", 12)
                    font.bold: true
                }
            }

            Text {
                id: headerValue
                anchors.right: parent.right
                text: monitor.cpuUsage.toFixed(0) + "%"
                color: Config.Settings.value("Annapurna Retro", "CpuWidget", "color_3", "#45b8ff")
                font.pixelSize: Config.Settings.value("Annapurna Retro", "CpuWidget", "font.pixelSize_2", 13)
                font.bold: true
            }
        }

        Graph {
            width: parent.width
            height: Config.Settings.value("Annapurna Retro", "CpuWidget", "height_3", 48)
            values: monitor.cpuHistory
            minimum: 0
            maximum: 100
        }
    }
}
