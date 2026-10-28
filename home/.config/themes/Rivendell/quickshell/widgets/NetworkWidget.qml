import "." as Config
import QtQuick

Rectangle {
    id: root

    property var monitor
    property color downloadColor: "#aa8953"
    property color uploadColor: "#b9b59c"

    width: Config.Settings.value("Rivendell", "NetworkWidget", "width", 260)
    height: Config.Settings.value("Rivendell", "NetworkWidget", "height", 100)
    radius: Config.Settings.value("Rivendell", "NetworkWidget", "radius", 18)
    color: Config.Settings.value("Rivendell", "NetworkWidget", "color", "#1e241c")
    opacity: Config.Settings.value("Rivendell", "NetworkWidget", "opacity", 0.72)
    border.color: Config.Settings.value("Rivendell", "NetworkWidget", "border.color", "#76674b")
    border.width: Config.Settings.value("Rivendell", "NetworkWidget", "border.width", 1)
    Column {
        anchors.fill: parent
        anchors.margins: Config.Settings.value("Rivendell", "NetworkWidget", "anchors.margins", 14)
        spacing: Config.Settings.value("Rivendell", "NetworkWidget", "spacing", 5)
        Row {
            id: header
            width: parent.width
            spacing: Config.Settings.value("Rivendell", "NetworkWidget", "spacing_2", 6)
            Text {
                id: title
                text: "󰈀  NETWORK"
                color: Config.Settings.value("Rivendell", "NetworkWidget", "color_2", "#b9b59c")
                font.family: Config.Settings.value("Rivendell", "NetworkWidget", "font.family", "JetBrainsMono Nerd Font")
                font.pixelSize: Config.Settings.value("Rivendell", "NetworkWidget", "font.pixelSize", 12)
                font.bold: true
            }

            Text {
                width: (header.width - title.width - 2 * header.spacing) / 2
                height: title.height
                text: "↓ " + formatRate(root.monitor.networkDownload)
                color: root.downloadColor
                font.pixelSize: Config.Settings.value("Rivendell", "NetworkWidget", "font.pixelSize_2", 12)
                minimumPixelSize: 8
                fontSizeMode: Text.HorizontalFit
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignRight
            }

            Text {
                width: (header.width - title.width - 2 * header.spacing) / 2
                height: title.height
                text: "↑ " + formatRate(root.monitor.networkUpload)
                color: root.uploadColor
                font.pixelSize: Config.Settings.value("Rivendell", "NetworkWidget", "font.pixelSize_3", 12)
                minimumPixelSize: 8
                fontSizeMode: Text.HorizontalFit
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignRight
            }
        }

        Item {
            width: parent.width
            height: Config.Settings.value("Rivendell", "NetworkWidget", "height_2", 48)
            property real sharedMaximum: Math.max(
                graphMaximum(root.monitor.downloadHistory),
                graphMaximum(root.monitor.uploadHistory))

            Graph {
                anchors.fill: parent
                values: root.monitor.downloadHistory
                minimum: 0
                maximum: parent.sharedMaximum
                lineColor: root.downloadColor
            }

            Graph {
                anchors.fill: parent
                values: root.monitor.uploadHistory
                minimum: 0
                maximum: parent.sharedMaximum
                lineColor: root.uploadColor
            }
        }
    }

    function graphMaximum(values) {
        var max = 1024 * 1024

        for (var i = 0; i < values.length; i++)
            max = Math.max(max, values[i] * 1.15)

        return max
    }

    function formatRate(bytes) {
        if (bytes < 1024)
            return bytes.toFixed(0) + " B/s"

        if (bytes < 1024 * 1024)
            return (bytes / 1024).toFixed(1) + " KB/s"

        if (bytes < 1024 * 1024 * 1024)
            return (bytes / (1024 * 1024)).toFixed(1) + " MB/s"

        return (bytes / (1024 * 1024 * 1024)).toFixed(1) + " GB/s"
    }
}
