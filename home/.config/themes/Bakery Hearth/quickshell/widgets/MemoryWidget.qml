import "." as Config
import QtQuick

Rectangle {
    id: root

    property var monitor

    width: Config.Settings.value("Bakery Hearth", "MemoryWidget", "width", 260)
    height: Config.Settings.value("Bakery Hearth", "MemoryWidget", "height", 100)
    radius: Config.Settings.value("Bakery Hearth", "MemoryWidget", "radius", 4)
    color: Config.Settings.value("Bakery Hearth", "MemoryWidget", "color", "#dc5a3e2e")
    opacity: Config.Settings.value("Bakery Hearth", "MemoryWidget", "opacity", 1.0)
    border.color: Config.Settings.value("Bakery Hearth", "MemoryWidget", "border.color", "#b58c6b")
    border.width: Config.Settings.value("Bakery Hearth", "MemoryWidget", "border.width", 1)
    Column {
        anchors.fill: parent
        anchors.margins: Config.Settings.value("Bakery Hearth", "MemoryWidget", "anchors.margins", 14)
        spacing: Config.Settings.value("Bakery Hearth", "MemoryWidget", "spacing", 5)
        Item {
            width: parent.width
            height: Math.max(headerLabel.implicitHeight, headerValue.implicitHeight)
            Row {
                id: headerLabel
                anchors.left: parent.left
                Text {
                    text: "󰍛  MEMORY"
                    color: Config.Settings.value("Bakery Hearth", "MemoryWidget", "color_2", "#dfb88e")
                    font.family: Config.Settings.value("Bakery Hearth", "MemoryWidget", "font.family", "JetBrainsMono Nerd Font")
                    font.pixelSize: Config.Settings.value("Bakery Hearth", "MemoryWidget", "font.pixelSize", 12)
                    font.bold: true
                }
            }

            Text {
                id: headerValue
                anchors.right: parent.right
                text: monitor.memoryUsage.toFixed(0) + "%"
                color: Config.Settings.value("Bakery Hearth", "MemoryWidget", "color_3", "#fce3c1")
                font.pixelSize: Config.Settings.value("Bakery Hearth", "MemoryWidget", "font.pixelSize_2", 13)
                font.bold: true
            }
        }

        Graph {
            width: parent.width
            height: Config.Settings.value("Bakery Hearth", "MemoryWidget", "height_3", 48)
            values: monitor.memoryHistory
            minimum: 0
            maximum: 100
        }
    }
}
