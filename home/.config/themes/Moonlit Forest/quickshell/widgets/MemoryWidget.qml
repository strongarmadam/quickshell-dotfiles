import "." as Config
import QtQuick

Rectangle {
    property var monitor

    width: Config.Settings.value("Moonlit Forest", "MemoryWidget", "width", 260)
    height: Config.Settings.value("Moonlit Forest", "MemoryWidget", "height", 100)
    radius: Config.Settings.value("Moonlit Forest", "MemoryWidget", "radius", 0)
    color: Config.Settings.value("Moonlit Forest", "MemoryWidget", "color", "#b8030609")
    opacity: Config.Settings.value("Moonlit Forest", "MemoryWidget", "opacity", 1.0)
    border.color: Config.Settings.value("Moonlit Forest", "MemoryWidget", "border.color", "#155779")
    border.width: Config.Settings.value("Moonlit Forest", "MemoryWidget", "border.width", 3)
    Column {
        anchors.fill: parent
        anchors.margins: Config.Settings.value("Moonlit Forest", "MemoryWidget", "anchors.margins", 14)
        spacing: Config.Settings.value("Moonlit Forest", "MemoryWidget", "spacing", 5)
        Item {
            width: parent.width
            height: Math.max(headerLabel.implicitHeight, headerValue.implicitHeight)
            Row {
                id: headerLabel
                anchors.left: parent.left
                Text {
                    text: "󰍛  MEMORY"
                    color: Config.Settings.value("Moonlit Forest", "MemoryWidget", "color_2", "#3aa9d2")
                    font.family: Config.Settings.value("Moonlit Forest", "MemoryWidget", "font.family", "JetBrainsMono Nerd Font")
                    font.pixelSize: Config.Settings.value("Moonlit Forest", "MemoryWidget", "font.pixelSize", 12)
                    font.bold: true
                }
            }

            Text {
                id: headerValue
                anchors.right: parent.right
                text: monitor.memoryUsage.toFixed(0) + "%"
                color: Config.Settings.value("Moonlit Forest", "MemoryWidget", "color_3", "#3aa9d2")
                font.pixelSize: Config.Settings.value("Moonlit Forest", "MemoryWidget", "font.pixelSize_2", 13)
                font.bold: true
            }
        }

        Graph {
            width: parent.width
            height: Config.Settings.value("Moonlit Forest", "MemoryWidget", "height_3", 48)
            values: monitor.memoryHistory
            minimum: 0
            maximum: 100
        }
    }
}
