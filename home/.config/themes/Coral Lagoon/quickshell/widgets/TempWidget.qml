import "." as Config
import QtQuick

Rectangle {
    property var monitor

    width: Config.Settings.value("Coral Lagoon", "TempWidget", "width", 260)
    height: Config.Settings.value("Coral Lagoon", "TempWidget", "height", 100)
    radius: Math.min(width, height) / 2
    color: Config.Settings.value("Coral Lagoon", "TempWidget", "color", "#b8062b40")
    opacity: Config.Settings.value("Coral Lagoon", "TempWidget", "opacity", 1.0)
    border.color: Config.Settings.value("Coral Lagoon", "TempWidget", "border.color", "#6bbacb")
    border.width: Config.Settings.value("Coral Lagoon", "TempWidget", "border.width", 3)
    Column {
        anchors.fill: parent
        anchors.margins: Config.Settings.value("Coral Lagoon", "TempWidget", "anchors.margins", 24)
        spacing: Config.Settings.value("Coral Lagoon", "TempWidget", "spacing", 5)
        Item {
            width: parent.width
            height: Math.max(headerLabel.implicitHeight, headerValue.implicitHeight)
            Row {
                id: headerLabel
                anchors.left: parent.left
                Text {
                    text: "  TEMP"
                    color: Config.Settings.value("Coral Lagoon", "TempWidget", "color_2", "#efb957")
                    font.family: Config.Settings.value("Coral Lagoon", "TempWidget", "font.family", "JetBrainsMono Nerd Font")
                    font.pixelSize: Config.Settings.value("Coral Lagoon", "TempWidget", "font.pixelSize", 12)
                    font.bold: true
                }
            }

            Text {
                id: headerValue
                anchors.right: parent.right
                text: monitor.cpuTemp.toFixed(0) + "°C"
                color: Config.Settings.value("Coral Lagoon", "TempWidget", "color_3", "#e5f6ff")
                font.pixelSize: Config.Settings.value("Coral Lagoon", "TempWidget", "font.pixelSize_2", 13)
                font.bold: true
            }
        }

        Graph {
            width: parent.width
            height: Config.Settings.value("Coral Lagoon", "TempWidget", "height_3", 48)
            values: monitor.tempHistory
            minimum: 20
            maximum: 90
        }
    }
}
