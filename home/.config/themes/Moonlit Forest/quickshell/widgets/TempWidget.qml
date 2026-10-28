import "." as Config
import QtQuick

Rectangle {
    property var monitor

    width: Config.Settings.value("Moonlit Forest", "TempWidget", "width", 260)
    height: Config.Settings.value("Moonlit Forest", "TempWidget", "height", 100)
    radius: Config.Settings.value("Moonlit Forest", "TempWidget", "radius", 0)
    color: Config.Settings.value("Moonlit Forest", "TempWidget", "color", "#b8030609")
    opacity: Config.Settings.value("Moonlit Forest", "TempWidget", "opacity", 1.0)
    border.color: Config.Settings.value("Moonlit Forest", "TempWidget", "border.color", "#155779")
    border.width: Config.Settings.value("Moonlit Forest", "TempWidget", "border.width", 3)
    Column {
        anchors.fill: parent
        anchors.margins: Config.Settings.value("Moonlit Forest", "TempWidget", "anchors.margins", 14)
        spacing: Config.Settings.value("Moonlit Forest", "TempWidget", "spacing", 5)
        Row {
            width: parent.width

            Text {
                text: "  TEMP"
                color: Config.Settings.value("Moonlit Forest", "TempWidget", "color_2", "#3aa9d2")
                font.family: Config.Settings.value("Moonlit Forest", "TempWidget", "font.family", "JetBrainsMono Nerd Font")
                font.pixelSize: Config.Settings.value("Moonlit Forest", "TempWidget", "font.pixelSize", 12)
                font.bold: true
            }

            Item {
                width: parent.width - 110
                height: Config.Settings.value("Moonlit Forest", "TempWidget", "height_2", 1)
            }

            Text {
                text: monitor.cpuTemp.toFixed(0) + "°C"
                color: Config.Settings.value("Moonlit Forest", "TempWidget", "color_3", "#3aa9d2")
                font.pixelSize: Config.Settings.value("Moonlit Forest", "TempWidget", "font.pixelSize_2", 13)
                font.bold: true
            }
        }

        Graph {
            width: parent.width
            height: Config.Settings.value("Moonlit Forest", "TempWidget", "height_3", 48)
            values: monitor.tempHistory
            minimum: 20
            maximum: 90
        }
    }
}
