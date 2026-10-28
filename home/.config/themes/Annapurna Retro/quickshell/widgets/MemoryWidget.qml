import "." as Config
import QtQuick

Rectangle {
    property var monitor

    width: Config.Settings.value("Annapurna Retro", "MemoryWidget", "width", 260)
    height: Config.Settings.value("Annapurna Retro", "MemoryWidget", "height", 100)
    radius: Config.Settings.value("Annapurna Retro", "MemoryWidget", "radius", 0)
    color: Config.Settings.value("Annapurna Retro", "MemoryWidget", "color", "#b810354d")
    opacity: Config.Settings.value("Annapurna Retro", "MemoryWidget", "opacity", 1.0)
    border.color: Config.Settings.value("Annapurna Retro", "MemoryWidget", "border.color", "#ffffff")
    border.width: Config.Settings.value("Annapurna Retro", "MemoryWidget", "border.width", 3)
    Column {
        anchors.fill: parent
        anchors.margins: Config.Settings.value("Annapurna Retro", "MemoryWidget", "anchors.margins", 14)
        spacing: Config.Settings.value("Annapurna Retro", "MemoryWidget", "spacing", 5)
        Row {
            width: parent.width

            Text {
                text: "󰍛  MEMORY"
                color: Config.Settings.value("Annapurna Retro", "MemoryWidget", "color_2", "#45b8ff")
                font.family: Config.Settings.value("Annapurna Retro", "MemoryWidget", "font.family", "JetBrainsMono Nerd Font")
                font.pixelSize: Config.Settings.value("Annapurna Retro", "MemoryWidget", "font.pixelSize", 12)
                font.bold: true
            }

            Item {
                width: parent.width - 145
                height: Config.Settings.value("Annapurna Retro", "MemoryWidget", "height_2", 1)
            }

            Text {
                text: monitor.memoryUsage.toFixed(0) + "%"
                color: Config.Settings.value("Annapurna Retro", "MemoryWidget", "color_3", "#45b8ff")
                font.pixelSize: Config.Settings.value("Annapurna Retro", "MemoryWidget", "font.pixelSize_2", 13)
                font.bold: true
            }
        }

        Graph {
            width: parent.width
            height: Config.Settings.value("Annapurna Retro", "MemoryWidget", "height_3", 48)
            values: monitor.memoryHistory
            minimum: 0
            maximum: 100
        }
    }
}
