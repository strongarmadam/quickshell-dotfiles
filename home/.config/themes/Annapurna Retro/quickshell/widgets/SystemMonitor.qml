import "." as Config
import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: root

    property real cpuUsage: 0
    property real memoryUsage: 0
    property real cpuTemp: 0

    property real networkDownload: 0
    property real networkUpload: 0

    property var cpuHistory: []
    property var memoryHistory: []
    property var tempHistory: []
    property var downloadHistory: []
    property var uploadHistory: []

    property var cpuPrevious: [0, 0]
    property var networkPrevious: [0, 0]

    function addSample(history, value) {
        var next = history.slice()
        next.push(value)

        if (next.length > 30)
            next.shift()

        return next
    }

    Process {
        id: statsProcess

        command: [
            "sh", "-c",
            "awk '/^cpu / {idle=$5+$6; total=0; for(i=2;i<=NF;i++) total+=$i; printf \"CPU %.0f %.0f\\n\", total, idle} /^MemTotal:/ {t=$2} /^MemAvailable:/ {a=$2} END {printf \"MEM %.0f\\n\", (1-a/t)*100}' /proc/stat /proc/meminfo"
        ]

        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                var lines = text.trim().split("\n")

                for (var line of lines) {
                    var parts = line.split(" ")

                    if (parts[0] === "CPU") {
                        var total = parseFloat(parts[1])
                        var idle = parseFloat(parts[2])

                        if (root.cpuPrevious[0] > 0) {
                            var totalDelta =
                                total - root.cpuPrevious[0]

                            var idleDelta =
                                idle - root.cpuPrevious[1]

                            if (totalDelta > 0) {
                                root.cpuUsage =
                                    Math.max(
                                        0,
                                        Math.min(
                                            100,
                                            (1 - idleDelta / totalDelta) * 100
                                        )
                                    )
                            }
                        }

                        root.cpuPrevious = [total, idle]

                        root.cpuHistory =
                            root.addSample(
                                root.cpuHistory,
                                root.cpuUsage
                            )
                    }

                    if (parts[0] === "MEM") {
                        root.memoryUsage =
                            parseFloat(parts[1])

                        root.memoryHistory =
                            root.addSample(
                                root.memoryHistory,
                                root.memoryUsage
                            )
                    }
                }
            }
        }
    }

    Process {
        id: tempProcess

        command: ["python3", Quickshell.env("HOME") + "/.config/hypr/scripts/cpu-temperature.py"]

        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                var value = parseFloat(text.trim())

                if (!isNaN(value)) {
                    root.cpuTemp = value / 1000

                    root.tempHistory =
                        root.addSample(
                            root.tempHistory,
                            root.cpuTemp
                        )
                }
            }
        }
    }

    Process {
        id: networkProcess

        command: [
            "sh", "-c",
            "awk 'NR>2 && $1 !~ /lo:/ {gsub(\":\", \"\", $1); rx+=$2; tx+=$10} END {printf \"NET %.0f %.0f\\n\", rx, tx}' /proc/net/dev"
        ]

        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                var parts = text.trim().split(" ")

                if (parts[0] === "NET") {
                    var rx = parseFloat(parts[1])
                    var tx = parseFloat(parts[2])

                    if (root.networkPrevious[0] > 0) {
                        var rxDelta =
                            Math.max(0, rx - root.networkPrevious[0])

                        var txDelta =
                            Math.max(0, tx - root.networkPrevious[1])

                        // Bytes per second, sampled every 2 seconds.
                        root.networkDownload = rxDelta / 2
                        root.networkUpload = txDelta / 2

                        root.downloadHistory =
                            root.addSample(
                                root.downloadHistory,
                                root.networkDownload
                            )

                        root.uploadHistory =
                            root.addSample(
                                root.uploadHistory,
                                root.networkUpload
                            )
                    }

                    root.networkPrevious = [rx, tx]
                }
            }
        }
    }

    Timer {
        interval: Config.Settings.value("Annapurna Retro", "SystemMonitor", "interval", 2000)
        running: true
        repeat: true

        onTriggered: {
            statsProcess.running = true
            tempProcess.running = true
            networkProcess.running = true
        }
    }
}
