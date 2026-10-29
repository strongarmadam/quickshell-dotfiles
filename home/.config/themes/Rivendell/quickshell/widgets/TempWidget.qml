import "." as Config
import QtQuick

Rectangle {
    id: root

    property var monitor

    width: Config.Settings.value("Rivendell", "TempWidget", "width", 260)
    height: Config.Settings.value("Rivendell", "TempWidget", "height", 100)
    radius: Config.Settings.value("Rivendell", "TempWidget", "radius", 18)
    color: Config.Settings.value("Rivendell", "TempWidget", "color", "#1e241c")
    opacity: Config.Settings.value("Rivendell", "TempWidget", "opacity", 0.70)
    border.color: Config.Settings.value("Rivendell", "TempWidget", "border.color", "#76674b")
    border.width: Config.Settings.value("Rivendell", "TempWidget", "border.width", 1)
    Column {
        anchors.fill: parent
        anchors.margins: Config.Settings.value("Rivendell", "TempWidget", "anchors.margins", 14)
        spacing: Config.Settings.value("Rivendell", "TempWidget", "spacing", 5)
        Item {
            width: parent.width
            height: Math.max(headerLabel.implicitHeight, headerValue.implicitHeight)
            Row {
                id: headerLabel
                anchors.left: parent.left
                Text {
                    text: "  TEMP"
                    color: Config.Settings.value("Rivendell", "TempWidget", "color_2", "#b9b59c")
                    font.family: Config.Settings.value("Rivendell", "TempWidget", "font.family", "JetBrainsMono Nerd Font")
                    font.pixelSize: Config.Settings.value("Rivendell", "TempWidget", "font.pixelSize", 12)
                    font.bold: true
                }
            }

            Text {
                id: headerValue
                anchors.right: parent.right
                text: monitor.cpuTemp.toFixed(0) + "°C"
                color: Config.Settings.value("Rivendell", "TempWidget", "color_3", "#e2dcc5")
                font.pixelSize: Config.Settings.value("Rivendell", "TempWidget", "font.pixelSize_2", 13)
                font.bold: true
            }
        }

        Graph {
            width: parent.width
            height: Config.Settings.value("Rivendell", "TempWidget", "height_3", 48)
            values: monitor.tempHistory
            minimum: 20
            maximum: 90
        }
    }
}
