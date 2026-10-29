import "." as Config
import QtQuick

Rectangle {
    property var monitor

    width: Config.Settings.value("16-bit Sunset", "CpuWidget", "width", 260)
    height: Config.Settings.value("16-bit Sunset", "CpuWidget", "height", 100)
    radius: Config.Settings.value("16-bit Sunset", "CpuWidget", "radius", 0)
    color: Config.Settings.value("16-bit Sunset", "CpuWidget", "color", "#b8292447")
    opacity: Config.Settings.value("16-bit Sunset", "CpuWidget", "opacity", 1.0)
    border.color: Config.Settings.value("16-bit Sunset", "CpuWidget", "border.color", "#51406b")
    border.width: Config.Settings.value("16-bit Sunset", "CpuWidget", "border.width", 3)
    Column {
        anchors.fill: parent
        anchors.margins: Config.Settings.value("16-bit Sunset", "CpuWidget", "anchors.margins", 14)
        spacing: Config.Settings.value("16-bit Sunset", "CpuWidget", "spacing", 5)
        Item {
            width: parent.width
            height: Math.max(headerLabel.implicitHeight, headerValue.implicitHeight)
            Row {
                id: headerLabel
                anchors.left: parent.left
                Text {
                    text: "  CPU"
                    color: Config.Settings.value("16-bit Sunset", "CpuWidget", "color_2", "#d47755")
                    font.family: Config.Settings.value("16-bit Sunset", "CpuWidget", "font.family", "JetBrainsMono Nerd Font")
                    font.pixelSize: Config.Settings.value("16-bit Sunset", "CpuWidget", "font.pixelSize", 12)
                    font.bold: true
                }
            }

            Text {
                id: headerValue
                anchors.right: parent.right
                text: monitor.cpuUsage.toFixed(0) + "%"
                color: Config.Settings.value("16-bit Sunset", "CpuWidget", "color_3", "#d47755")
                font.pixelSize: Config.Settings.value("16-bit Sunset", "CpuWidget", "font.pixelSize_2", 13)
                font.bold: true
            }
        }

        Graph {
            width: parent.width
            height: Config.Settings.value("16-bit Sunset", "CpuWidget", "height_3", 48)
            values: monitor.cpuHistory
            minimum: 0
            maximum: 100
        }
    }
}
