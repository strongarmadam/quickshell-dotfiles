import "." as Config
import QtQuick

Rectangle {
    id: root

    property var monitor

    width: Config.Settings.value("Autumn Grove", "TempWidget", "width", 260)
    height: Config.Settings.value("Autumn Grove", "TempWidget", "height", 100)
    radius: Config.Settings.value("Autumn Grove", "TempWidget", "radius", 18)
    color: Config.Settings.value("Autumn Grove", "TempWidget", "color", "#241b16")
    opacity: Config.Settings.value("Autumn Grove", "TempWidget", "opacity", 0.70)
    border.color: Config.Settings.value("Autumn Grove", "TempWidget", "border.color", "#a89270")
    border.width: Config.Settings.value("Autumn Grove", "TempWidget", "border.width", 1)
    Column {
        anchors.fill: parent
        anchors.margins: Config.Settings.value("Autumn Grove", "TempWidget", "anchors.margins", 14)
        spacing: Config.Settings.value("Autumn Grove", "TempWidget", "spacing", 5)
        Item {
            width: parent.width
            height: Math.max(headerLabel.implicitHeight, headerValue.implicitHeight)
            Row {
                id: headerLabel
                anchors.left: parent.left
                Text {
                    text: "  TEMP"
                    color: Config.Settings.value("Autumn Grove", "TempWidget", "color_2", "#b8a789")
                    font.family: Config.Settings.value("Autumn Grove", "TempWidget", "font.family", "JetBrainsMono Nerd Font")
                    font.pixelSize: Config.Settings.value("Autumn Grove", "TempWidget", "font.pixelSize", 12)
                    font.bold: true
                }
            }

            Text {
                id: headerValue
                anchors.right: parent.right
                text: monitor.cpuTemp.toFixed(0) + "°C"
                color: Config.Settings.value("Autumn Grove", "TempWidget", "color_3", "#e5d8bd")
                font.pixelSize: Config.Settings.value("Autumn Grove", "TempWidget", "font.pixelSize_2", 13)
                font.bold: true
            }
        }

        Graph {
            width: parent.width
            height: Config.Settings.value("Autumn Grove", "TempWidget", "height_3", 48)
            values: monitor.tempHistory
            minimum: 20
            maximum: 90
        }
    }
}
