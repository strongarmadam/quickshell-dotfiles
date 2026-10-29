import "." as Config
import QtQuick

Rectangle {
    property var monitor

    width: Config.Settings.value("16-bit Sunset", "TempWidget", "width", 260)
    height: Config.Settings.value("16-bit Sunset", "TempWidget", "height", 100)
    radius: Config.Settings.value("16-bit Sunset", "TempWidget", "radius", 0)
    color: Config.Settings.value("16-bit Sunset", "TempWidget", "color", "#b8292447")
    opacity: Config.Settings.value("16-bit Sunset", "TempWidget", "opacity", 1.0)
    border.color: Config.Settings.value("16-bit Sunset", "TempWidget", "border.color", "#51406b")
    border.width: Config.Settings.value("16-bit Sunset", "TempWidget", "border.width", 3)
    Column {
        anchors.fill: parent
        anchors.margins: Config.Settings.value("16-bit Sunset", "TempWidget", "anchors.margins", 14)
        spacing: Config.Settings.value("16-bit Sunset", "TempWidget", "spacing", 5)
        Item {
            width: parent.width
            height: Math.max(headerLabel.implicitHeight, headerValue.implicitHeight)
            Row {
                id: headerLabel
                anchors.left: parent.left
                Text {
                    text: "  TEMP"
                    color: Config.Settings.value("16-bit Sunset", "TempWidget", "color_2", "#d47755")
                    font.family: Config.Settings.value("16-bit Sunset", "TempWidget", "font.family", "JetBrainsMono Nerd Font")
                    font.pixelSize: Config.Settings.value("16-bit Sunset", "TempWidget", "font.pixelSize", 12)
                    font.bold: true
                }
            }

            Text {
                id: headerValue
                anchors.right: parent.right
                text: monitor.cpuTemp.toFixed(0) + "°C"
                color: Config.Settings.value("16-bit Sunset", "TempWidget", "color_3", "#d47755")
                font.pixelSize: Config.Settings.value("16-bit Sunset", "TempWidget", "font.pixelSize_2", 13)
                font.bold: true
            }
        }

        Graph {
            width: parent.width
            height: Config.Settings.value("16-bit Sunset", "TempWidget", "height_3", 48)
            values: monitor.tempHistory
            minimum: 20
            maximum: 90
        }
    }
}
