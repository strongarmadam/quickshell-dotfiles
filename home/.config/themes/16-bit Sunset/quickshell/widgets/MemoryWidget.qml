import "." as Config
import QtQuick

Rectangle {
    property var monitor

    width: Config.Settings.value("16-bit Sunset", "MemoryWidget", "width", 260)
    height: Config.Settings.value("16-bit Sunset", "MemoryWidget", "height", 100)
    radius: Config.Settings.value("16-bit Sunset", "MemoryWidget", "radius", 0)
    color: Config.Settings.value("16-bit Sunset", "MemoryWidget", "color", "#b8292447")
    opacity: Config.Settings.value("16-bit Sunset", "MemoryWidget", "opacity", 1.0)
    border.color: Config.Settings.value("16-bit Sunset", "MemoryWidget", "border.color", "#51406b")
    border.width: Config.Settings.value("16-bit Sunset", "MemoryWidget", "border.width", 3)
    Column {
        anchors.fill: parent
        anchors.margins: Config.Settings.value("16-bit Sunset", "MemoryWidget", "anchors.margins", 14)
        spacing: Config.Settings.value("16-bit Sunset", "MemoryWidget", "spacing", 5)
        Item {
            width: parent.width
            height: Math.max(headerLabel.implicitHeight, headerValue.implicitHeight)
            Row {
                id: headerLabel
                anchors.left: parent.left
                Text {
                    text: "󰍛  MEMORY"
                    color: Config.Settings.value("16-bit Sunset", "MemoryWidget", "color_2", "#d47755")
                    font.family: Config.Settings.value("16-bit Sunset", "MemoryWidget", "font.family", "JetBrainsMono Nerd Font")
                    font.pixelSize: Config.Settings.value("16-bit Sunset", "MemoryWidget", "font.pixelSize", 12)
                    font.bold: true
                }
            }

            Text {
                id: headerValue
                anchors.right: parent.right
                text: monitor.memoryUsage.toFixed(0) + "%"
                color: Config.Settings.value("16-bit Sunset", "MemoryWidget", "color_3", "#d47755")
                font.pixelSize: Config.Settings.value("16-bit Sunset", "MemoryWidget", "font.pixelSize_2", 13)
                font.bold: true
            }
        }

        Graph {
            width: parent.width
            height: Config.Settings.value("16-bit Sunset", "MemoryWidget", "height_3", 48)
            values: monitor.memoryHistory
            minimum: 0
            maximum: 100
        }
    }
}
