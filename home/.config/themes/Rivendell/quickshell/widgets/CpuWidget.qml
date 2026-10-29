import "." as Config
import QtQuick

Rectangle {
    id: root

    property var monitor

    width: Config.Settings.value("Rivendell", "CpuWidget", "width", 260)
    height: Config.Settings.value("Rivendell", "CpuWidget", "height", 100)
    radius: Config.Settings.value("Rivendell", "CpuWidget", "radius", 18)
    color: Config.Settings.value("Rivendell", "CpuWidget", "color", "#1e241c")
    opacity: Config.Settings.value("Rivendell", "CpuWidget", "opacity", 0.70)
    border.color: Config.Settings.value("Rivendell", "CpuWidget", "border.color", "#76674b")
    border.width: Config.Settings.value("Rivendell", "CpuWidget", "border.width", 1)
    Column {
        anchors.fill: parent
        anchors.margins: Config.Settings.value("Rivendell", "CpuWidget", "anchors.margins", 14)
        spacing: Config.Settings.value("Rivendell", "CpuWidget", "spacing", 5)
        Item {
            width: parent.width
            height: Math.max(headerLabel.implicitHeight, headerValue.implicitHeight)
            Row {
                id: headerLabel
                anchors.left: parent.left
                Item {
                    width: 22; height: 16
                    ThemeAppIcon { width: 16; height: 16; symbol: "ring"; ink: Config.Settings.value("Rivendell", "CpuWidget", "color_2", "#aa8953") }
                }
                Text {
                    text: "CPU"
                    color: Config.Settings.value("Rivendell", "CpuWidget", "color_2", "#aa8953")
                    font.family: Config.Settings.value("Rivendell", "CpuWidget", "font.family", "JetBrainsMono Nerd Font")
                    font.pixelSize: Config.Settings.value("Rivendell", "CpuWidget", "font.pixelSize", 12)
                    font.bold: true
                }
            }

            Text {
                id: headerValue
                anchors.right: parent.right
                text: monitor.cpuUsage.toFixed(0) + "%"
                color: Config.Settings.value("Rivendell", "CpuWidget", "color_3", "#e2dcc5")
                font.pixelSize: Config.Settings.value("Rivendell", "CpuWidget", "font.pixelSize_2", 13)
                font.bold: true
            }
        }

        Graph {
            width: parent.width
            height: Config.Settings.value("Rivendell", "CpuWidget", "height_3", 48)
            values: monitor.cpuHistory
            minimum: 0
            maximum: 100
        }
    }
}
