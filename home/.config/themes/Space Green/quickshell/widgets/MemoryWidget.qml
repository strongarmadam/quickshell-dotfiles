import "." as Config
import QtQuick

Rectangle {
    id: root

    property var monitor

    width: Config.Settings.value("Space Green", "MemoryWidget", "width", 260)
    height: Config.Settings.value("Space Green", "MemoryWidget", "height", 100)
    radius: Config.Settings.value("Space Green", "MemoryWidget", "radius", 18)
    color: Config.Settings.value("Space Green", "MemoryWidget", "color", "#0c1f18")
    opacity: Config.Settings.value("Space Green", "MemoryWidget", "opacity", 0.72)
    border.color: Config.Settings.value("Space Green", "MemoryWidget", "border.color", "#436b57")
    border.width: Config.Settings.value("Space Green", "MemoryWidget", "border.width", 1)
    Column {
        anchors.fill: parent
        anchors.margins: Config.Settings.value("Space Green", "MemoryWidget", "anchors.margins", 14)
        spacing: Config.Settings.value("Space Green", "MemoryWidget", "spacing", 5)
        Item {
            width: parent.width
            height: Math.max(headerLabel.implicitHeight, headerValue.implicitHeight)
            Row {
                id: headerLabel
                anchors.left: parent.left
                Text {
                    text: "󰍛  MEMORY"
                    color: Config.Settings.value("Space Green", "MemoryWidget", "color_2", "#f4b942")
                    font.family: Config.Settings.value("Space Green", "MemoryWidget", "font.family", "JetBrainsMono Nerd Font")
                    font.pixelSize: Config.Settings.value("Space Green", "MemoryWidget", "font.pixelSize", 12)
                    font.bold: true
                }
            }

            Text {
                id: headerValue
                anchors.right: parent.right
                text: monitor.memoryUsage.toFixed(0) + "%"
                color: Config.Settings.value("Space Green", "MemoryWidget", "color_3", "#d7e5dc")
                font.pixelSize: Config.Settings.value("Space Green", "MemoryWidget", "font.pixelSize_2", 13)
                font.bold: true
            }
        }

        Graph {
            width: parent.width
            height: Config.Settings.value("Space Green", "MemoryWidget", "height_3", 48)
            values: monitor.memoryHistory
            minimum: 0
            maximum: 100
        }
    }
}
