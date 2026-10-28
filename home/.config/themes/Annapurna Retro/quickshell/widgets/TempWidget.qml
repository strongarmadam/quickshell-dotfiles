import "." as Config
import QtQuick

Rectangle {
    property var monitor

    width: Config.Settings.value("Annapurna Retro", "TempWidget", "width", 260)
    height: Config.Settings.value("Annapurna Retro", "TempWidget", "height", 100)
    radius: Config.Settings.value("Annapurna Retro", "TempWidget", "radius", 0)
    color: Config.Settings.value("Annapurna Retro", "TempWidget", "color", "#b810354d")
    opacity: Config.Settings.value("Annapurna Retro", "TempWidget", "opacity", 1.0)
    border.color: Config.Settings.value("Annapurna Retro", "TempWidget", "border.color", "#ffffff")
    border.width: Config.Settings.value("Annapurna Retro", "TempWidget", "border.width", 3)
    Column {
        anchors.fill: parent
        anchors.margins: Config.Settings.value("Annapurna Retro", "TempWidget", "anchors.margins", 14)
        spacing: Config.Settings.value("Annapurna Retro", "TempWidget", "spacing", 5)
        Row {
            width: parent.width

            Text {
                text: "  TEMP"
                color: Config.Settings.value("Annapurna Retro", "TempWidget", "color_2", "#45b8ff")
                font.family: Config.Settings.value("Annapurna Retro", "TempWidget", "font.family", "JetBrainsMono Nerd Font")
                font.pixelSize: Config.Settings.value("Annapurna Retro", "TempWidget", "font.pixelSize", 12)
                font.bold: true
            }

            Item {
                width: parent.width - 110
                height: Config.Settings.value("Annapurna Retro", "TempWidget", "height_2", 1)
            }

            Text {
                text: monitor.cpuTemp.toFixed(0) + "°C"
                color: Config.Settings.value("Annapurna Retro", "TempWidget", "color_3", "#45b8ff")
                font.pixelSize: Config.Settings.value("Annapurna Retro", "TempWidget", "font.pixelSize_2", 13)
                font.bold: true
            }
        }

        Graph {
            width: parent.width
            height: Config.Settings.value("Annapurna Retro", "TempWidget", "height_3", 48)
            values: monitor.tempHistory
            minimum: 20
            maximum: 90
        }
    }
}
