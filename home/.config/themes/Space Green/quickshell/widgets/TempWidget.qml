import "." as Config
import QtQuick

Rectangle {
    id: root

    property var monitor

    width: Config.Settings.value("Space Green", "TempWidget", "width", 260)
    height: Config.Settings.value("Space Green", "TempWidget", "height", 100)
    radius: Config.Settings.value("Space Green", "TempWidget", "radius", 18)
    color: Config.Settings.value("Space Green", "TempWidget", "color", "#0c1f18")
    opacity: Config.Settings.value("Space Green", "TempWidget", "opacity", 0.72)
    border.color: Config.Settings.value("Space Green", "TempWidget", "border.color", "#436b57")
    border.width: Config.Settings.value("Space Green", "TempWidget", "border.width", 1)
    Column {
        anchors.fill: parent
        anchors.margins: Config.Settings.value("Space Green", "TempWidget", "anchors.margins", 14)
        spacing: Config.Settings.value("Space Green", "TempWidget", "spacing", 5)
        Row {
            width: parent.width

            Text {
                text: "  TEMP"
                color: Config.Settings.value("Space Green", "TempWidget", "color_2", "#f4b942")
                font.family: Config.Settings.value("Space Green", "TempWidget", "font.family", "JetBrainsMono Nerd Font")
                font.pixelSize: Config.Settings.value("Space Green", "TempWidget", "font.pixelSize", 12)
                font.bold: true
            }

            Item {
                width: parent.width - 110
                height: Config.Settings.value("Space Green", "TempWidget", "height_2", 1)
            }

            Text {
                text: monitor.cpuTemp.toFixed(0) + "°C"
                color: Config.Settings.value("Space Green", "TempWidget", "color_3", "#d7e5dc")
                font.pixelSize: Config.Settings.value("Space Green", "TempWidget", "font.pixelSize_2", 13)
                font.bold: true
            }
        }

        Graph {
            width: parent.width
            height: Config.Settings.value("Space Green", "TempWidget", "height_3", 48)
            values: monitor.tempHistory
            minimum: 20
            maximum: 90
        }
    }
}
