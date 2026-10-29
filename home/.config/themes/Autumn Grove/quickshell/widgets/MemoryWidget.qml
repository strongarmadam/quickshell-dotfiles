import "." as Config
import QtQuick

Rectangle {
    id: root

    property var monitor

    width: Config.Settings.value("Autumn Grove", "MemoryWidget", "width", 260)
    height: Config.Settings.value("Autumn Grove", "MemoryWidget", "height", 100)
    radius: Config.Settings.value("Autumn Grove", "MemoryWidget", "radius", 18)
    color: Config.Settings.value("Autumn Grove", "MemoryWidget", "color", "#241b16")
    opacity: Config.Settings.value("Autumn Grove", "MemoryWidget", "opacity", 0.70)
    border.color: Config.Settings.value("Autumn Grove", "MemoryWidget", "border.color", "#a89270")
    border.width: Config.Settings.value("Autumn Grove", "MemoryWidget", "border.width", 1)
    Column {
        anchors.fill: parent
        anchors.margins: Config.Settings.value("Autumn Grove", "MemoryWidget", "anchors.margins", 14)
        spacing: Config.Settings.value("Autumn Grove", "MemoryWidget", "spacing", 5)
        Item {
            width: parent.width
            height: Math.max(headerLabel.implicitHeight, headerValue.implicitHeight)
            Row {
                id: headerLabel
                anchors.left: parent.left
                Text {
                    text: "󰍛  MEMORY"
                    color: Config.Settings.value("Autumn Grove", "MemoryWidget", "color_2", "#c59b62")
                    font.family: Config.Settings.value("Autumn Grove", "MemoryWidget", "font.family", "JetBrainsMono Nerd Font")
                    font.pixelSize: Config.Settings.value("Autumn Grove", "MemoryWidget", "font.pixelSize", 12)
                    font.bold: true
                }
            }

            Text {
                id: headerValue
                anchors.right: parent.right
                text: monitor.memoryUsage.toFixed(0) + "%"
                color: Config.Settings.value("Autumn Grove", "MemoryWidget", "color_3", "#e5d8bd")
                font.pixelSize: Config.Settings.value("Autumn Grove", "MemoryWidget", "font.pixelSize_2", 13)
                font.bold: true
            }
        }

        Graph {
            width: parent.width
            height: Config.Settings.value("Autumn Grove", "MemoryWidget", "height_3", 48)
            values: monitor.memoryHistory
            minimum: 0
            maximum: 100
        }
    }
}
