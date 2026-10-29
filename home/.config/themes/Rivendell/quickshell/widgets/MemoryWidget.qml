import "." as Config
import QtQuick

Rectangle {
    id: root

    property var monitor

    width: Config.Settings.value("Rivendell", "MemoryWidget", "width", 260)
    height: Config.Settings.value("Rivendell", "MemoryWidget", "height", 100)
    radius: Config.Settings.value("Rivendell", "MemoryWidget", "radius", 18)
    color: Config.Settings.value("Rivendell", "MemoryWidget", "color", "#1e241c")
    opacity: Config.Settings.value("Rivendell", "MemoryWidget", "opacity", 0.70)
    border.color: Config.Settings.value("Rivendell", "MemoryWidget", "border.color", "#76674b")
    border.width: Config.Settings.value("Rivendell", "MemoryWidget", "border.width", 1)
    Column {
        anchors.fill: parent
        anchors.margins: Config.Settings.value("Rivendell", "MemoryWidget", "anchors.margins", 14)
        spacing: Config.Settings.value("Rivendell", "MemoryWidget", "spacing", 5)
        Item {
            width: parent.width
            height: Math.max(headerLabel.implicitHeight, headerValue.implicitHeight)
            Row {
                id: headerLabel
                anchors.left: parent.left
                Text {
                    text: "󰍛  MEMORY"
                    color: Config.Settings.value("Rivendell", "MemoryWidget", "color_2", "#aa8953")
                    font.family: Config.Settings.value("Rivendell", "MemoryWidget", "font.family", "JetBrainsMono Nerd Font")
                    font.pixelSize: Config.Settings.value("Rivendell", "MemoryWidget", "font.pixelSize", 12)
                    font.bold: true
                }
            }

            Text {
                id: headerValue
                anchors.right: parent.right
                text: monitor.memoryUsage.toFixed(0) + "%"
                color: Config.Settings.value("Rivendell", "MemoryWidget", "color_3", "#e2dcc5")
                font.pixelSize: Config.Settings.value("Rivendell", "MemoryWidget", "font.pixelSize_2", 13)
                font.bold: true
            }
        }

        Graph {
            width: parent.width
            height: Config.Settings.value("Rivendell", "MemoryWidget", "height_3", 48)
            values: monitor.memoryHistory
            minimum: 0
            maximum: 100
        }
    }
}
