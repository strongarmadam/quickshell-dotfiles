import "." as Config
import QtQuick

Rectangle {
    id: root

    property var monitor

    width: Config.Settings.value("Bakery Hearth", "TempWidget", "width", 260)
    height: Config.Settings.value("Bakery Hearth", "TempWidget", "height", 100)
    radius: Config.Settings.value("Bakery Hearth", "TempWidget", "radius", 4)
    color: Config.Settings.value("Bakery Hearth", "TempWidget", "color", "#dc5a3e2e")
    opacity: Config.Settings.value("Bakery Hearth", "TempWidget", "opacity", 1.0)
    border.color: Config.Settings.value("Bakery Hearth", "TempWidget", "border.color", "#b58c6b")
    border.width: Config.Settings.value("Bakery Hearth", "TempWidget", "border.width", 1)
    Column {
        anchors.fill: parent
        anchors.margins: Config.Settings.value("Bakery Hearth", "TempWidget", "anchors.margins", 14)
        spacing: Config.Settings.value("Bakery Hearth", "TempWidget", "spacing", 5)
        Row {
            width: parent.width

            Text {
                text: "  TEMP"
                color: Config.Settings.value("Bakery Hearth", "TempWidget", "color_2", "#cfb28f")
                font.family: Config.Settings.value("Bakery Hearth", "TempWidget", "font.family", "JetBrainsMono Nerd Font")
                font.pixelSize: Config.Settings.value("Bakery Hearth", "TempWidget", "font.pixelSize", 12)
                font.bold: true
            }

            Item {
                width: parent.width - 110
                height: Config.Settings.value("Bakery Hearth", "TempWidget", "height_2", 1)
            }

            Text {
                text: monitor.cpuTemp.toFixed(0) + "°C"
                color: Config.Settings.value("Bakery Hearth", "TempWidget", "color_3", "#fce3c1")
                font.pixelSize: Config.Settings.value("Bakery Hearth", "TempWidget", "font.pixelSize_2", 13)
                font.bold: true
            }
        }

        Graph {
            width: parent.width
            height: Config.Settings.value("Bakery Hearth", "TempWidget", "height_3", 48)
            values: monitor.tempHistory
            minimum: 20
            maximum: 90
        }
    }
}
