import "." as Config
import QtQuick

Rectangle {
    id: root
    property var monitor
    property color downloadColor: "#9bd65b"
    property color uploadColor: "#45b8ff"

    width: Config.Settings.value("Annapurna Retro", "NetworkWidget", "width", 260)
    height: Config.Settings.value("Annapurna Retro", "NetworkWidget", "height", 100)
    radius: Config.Settings.value("Annapurna Retro", "NetworkWidget", "radius", 0)
    color: Config.Settings.value("Annapurna Retro", "NetworkWidget", "color", "#b810354d")
    opacity: Config.Settings.value("Annapurna Retro", "NetworkWidget", "opacity", 1.0)
    border.color: Config.Settings.value("Annapurna Retro", "NetworkWidget", "border.color", "#ffffff")
    border.width: Config.Settings.value("Annapurna Retro", "NetworkWidget", "border.width", 3)
    Column {
        anchors.fill: parent
        anchors.margins: Config.Settings.value("Annapurna Retro", "NetworkWidget", "anchors.margins", 14)
        spacing: Config.Settings.value("Annapurna Retro", "NetworkWidget", "spacing", 5)
        Row {
            id: header
            width: parent.width
            spacing: Config.Settings.value("Annapurna Retro", "NetworkWidget", "spacing_2", 6)
            Text {
                id: title
                text: "󰈀  NETWORK"
                color: Config.Settings.value("Annapurna Retro", "NetworkWidget", "color_2", "#45b8ff")
                font.family: Config.Settings.value("Annapurna Retro", "NetworkWidget", "font.family", "JetBrainsMono Nerd Font")
                font.pixelSize: Config.Settings.value("Annapurna Retro", "NetworkWidget", "font.pixelSize", 12)
                font.bold: true
            }

            Text {
                width: (header.width - title.width - 2 * header.spacing) / 2
                height: title.height
                text: "↓ " + formatRate(root.monitor.networkDownload)
                color: root.downloadColor
                font.pixelSize: Config.Settings.value("Annapurna Retro", "NetworkWidget", "font.pixelSize_2", 12)
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
                font.pixelSize: Config.Settings.value("Annapurna Retro", "NetworkWidget", "font.pixelSize_3", 12)
                minimumPixelSize: 8
                fontSizeMode: Text.HorizontalFit
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignRight
            }
        }

        Item {
            width: parent.width
            height: Config.Settings.value("Annapurna Retro", "NetworkWidget", "height_2", 48)
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
