import "." as Config
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Mpris

MovableWidget {
    id: root
    property color panelColor: Config.Settings.value("Annapurna Retro", "MediaPanel", "panelColor", "#dc10354d")
    property color edgeColor: Config.Settings.value("Annapurna Retro", "MediaPanel", "edgeColor", "#ffffff")
    property color textColor: Config.Settings.value("Annapurna Retro", "MediaPanel", "textColor", "#f1faff")
    property color accentColor: Config.Settings.value("Annapurna Retro", "MediaPanel", "accentColor", "#9bd65b")
    property real panelOpacity: Config.Settings.value("Annapurna Retro", "MediaPanel", "panelOpacity", 1)
    property int cornerRadius: Config.Settings.value("Annapurna Retro", "MediaPanel", "cornerRadius", 0)
    property int edgeWidth: Config.Settings.value("Annapurna Retro", "MediaPanel", "edgeWidth", 3)
    readonly property var player: Mpris.players.values.find(p => p.isPlaying) || Mpris.players.values[0] || null
    readonly property bool needsAudio: player !== null && player.isPlaying
    property var levels: Array(16).fill(0)
    property var peaks: Array(16).fill(0)
    property bool connected: false
    readonly property var frequencies: ["31.5", "50", "80", "125", "200", "315", "500", "800",
                                        "1.25k", "2k", "3.15k", "5k", "8k", "10k", "12.5k", "16k"]

    visible: Config.Settings.value("shared", "Visibility", "media", true) && player !== null && layoutManager !== null && layoutManager.ready
    implicitWidth: Config.Settings.value("Annapurna Retro", "MediaPanel", "implicitWidth", 440)
    implicitHeight: Config.Settings.value("Annapurna Retro", "MediaPanel", "implicitHeight", 274)
    color: "transparent"

    onNeedsAudioChanged: {
        capture.running = needsAudio;
        if (!needsAudio) {
            levels = Array(16).fill(0);
            peaks = Array(16).fill(0);
            connected = false;
        }
    }
    Process {
        id: capture
        command: ["python3", "-u", Quickshell.env("HOME") + "/.local/lib/desktop-media/spectrum.py"]
        running: root.needsAudio
        stdout: SplitParser {
            onRead: data => {
                try {
                    const frame = JSON.parse(data);
                    if (frame.levels.length !== 16 || !root.needsAudio) return;
                    root.connected = frame.connected;
                    root.levels = frame.levels;
                    root.peaks = frame.levels.map((v, i) => Math.max(v, root.peaks[i] - 0.015));
                } catch (e) { console.warn("Media spectrum:", e); }
            }
        }
    }
    Timer {
        interval: Config.Settings.value("Annapurna Retro", "MediaPanel", "interval", 2000)
        repeat: true
        running: root.needsAudio && !capture.running
        onTriggered: capture.running = true
    }

    component TransportButton: Rectangle {
        property string glyph
        property string label
        property bool available: true
        signal activated()
        width: 48; height: 34
        radius: Math.min(6, root.cornerRadius)
        color: pointer.containsMouse && available ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.25)
                                                 : Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.10)
        border.color: Qt.rgba(root.edgeColor.r, root.edgeColor.g, root.edgeColor.b, 0.55)
        border.width: Config.Settings.value("Annapurna Retro", "MediaPanel", "border.width", 3)
        opacity: available ? 1 : 0.35
        Text {
            anchors.centerIn: parent
            text: parent.glyph
            color: root.textColor
            font.family: Config.Settings.value("Annapurna Retro", "MediaPanel", "font.family", "JetBrainsMono Nerd Font")
            font.pixelSize: Config.Settings.value("Annapurna Retro", "MediaPanel", "font.pixelSize", 19)
        }
        MouseArea {
            id: pointer
            anchors.fill: parent
            hoverEnabled: true
            enabled: parent.available
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.activated()
        }
        ToolTip.visible: pointer.containsMouse
        ToolTip.text: label
        Accessible.name: label
        Accessible.role: Accessible.Button
    }

    Rectangle {
        anchors.fill: parent
        radius: root.cornerRadius
        color: root.panelColor
        opacity: root.panelOpacity
        border.color: root.edgeColor
        border.width: root.edgeWidth
        Column {
            anchors.fill: parent
            anchors.margins: Config.Settings.value("Annapurna Retro", "MediaPanel", "anchors.margins", 16)
            spacing: Config.Settings.value("Annapurna Retro", "MediaPanel", "spacing", 9)
            Row {
                width: parent.width
                Text {
                    width: parent.width / 2
                    text: "󰎆  MEDIA"
                    color: root.accentColor
                    font.family: Config.Settings.value("Annapurna Retro", "MediaPanel", "font.family_2", "JetBrainsMono Nerd Font")
                    font.pixelSize: Config.Settings.value("Annapurna Retro", "MediaPanel", "font.pixelSize_2", 12)
                    font.bold: true
                }
                Text {
                    width: parent.width / 2
                    horizontalAlignment: Text.AlignRight
                    text: !root.needsAudio ? "PAUSED" : root.connected ? "16-BAND LIVE" : "CONNECTING AUDIO"
                    color: root.accentColor
                    font.pixelSize: Config.Settings.value("Annapurna Retro", "MediaPanel", "font.pixelSize_3", 10)
                }
            }
            Text {
                width: parent.width
                text: root.player ? (root.player.trackTitle || "Choose media in your player") : ""
                color: root.textColor
                font.pixelSize: Config.Settings.value("Annapurna Retro", "MediaPanel", "font.pixelSize_4", 17)
                font.bold: true
                elide: Text.ElideRight
            }
            Text {
                width: parent.width
                text: root.player ? (root.player.trackArtist || "Unknown artist") : ""
                color: root.accentColor
                font.pixelSize: Config.Settings.value("Annapurna Retro", "MediaPanel", "font.pixelSize_5", 12)
                elide: Text.ElideRight
            }
            Item {
                id: spectrum
                width: parent.width
                height: Config.Settings.value("Annapurna Retro", "MediaPanel", "height", 114)
                Canvas {
                    id: bars
                    anchors { fill: parent; bottomMargin: 19 }
                    onPaint: {
                        const ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);
                        const step = width / 16;
                        ctx.strokeStyle = Qt.rgba(root.edgeColor.r, root.edgeColor.g, root.edgeColor.b, 0.3);
                        ctx.lineWidth = 1;
                        for (let row = 0; row < 4; row++) {
                            const y = 1 + row * (height - 2) / 3;
                            ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(width, y); ctx.stroke();
                        }
                        for (let i = 0; i < 16; i++) {
                            const level = root.needsAudio ? root.levels[i] : 0;
                            const barHeight = Math.max(2, level * (height - 3));
                            const x = i * step + 3;
                            const w = step - 6;
                            ctx.fillStyle = root.accentColor;
                            ctx.fillRect(x, height - barHeight, w, barHeight);
                            if (root.needsAudio && root.peaks[i] > 0.02) {
                                ctx.fillStyle = root.textColor;
                                ctx.fillRect(x, height - root.peaks[i] * (height - 3), w, 2);
                            }
                        }
                    }
                }
                Connections {
                    target: root
                    function onLevelsChanged() { bars.requestPaint(); }
                    function onPeaksChanged() { bars.requestPaint(); }
                    function onNeedsAudioChanged() { bars.requestPaint(); }
                }
                Row {
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                    Repeater {
                        model: root.frequencies
                        Text {
                            required property string modelData
                            width: spectrum.width / 16
                            text: modelData
                            horizontalAlignment: Text.AlignHCenter
                            color: root.accentColor
                            font.pixelSize: Config.Settings.value("Annapurna Retro", "MediaPanel", "font.pixelSize_6", 8)
                        }
                    }
                }
            }
            Row {
                width: parent.width
                Text {
                    width: (parent.width - 164) / 2
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Hz · −72 to 0 dBFS"
                    color: root.accentColor
                    font.pixelSize: Config.Settings.value("Annapurna Retro", "MediaPanel", "font.pixelSize_7", 9)
                }
                Row {
                    spacing: Config.Settings.value("Annapurna Retro", "MediaPanel", "spacing_2", 10)
                    TransportButton {
                        glyph: "⏮"; label: "Previous track"
                        available: root.player !== null && root.player.canGoPrevious
                        onActivated: root.player.previous()
                    }
                    TransportButton {
                        glyph: root.needsAudio ? "⏸" : "▶"
                        label: root.needsAudio ? "Pause" : "Play"
                        available: root.player !== null && root.player.canTogglePlaying
                        onActivated: root.player.togglePlaying()
                    }
                    TransportButton {
                        glyph: "⏭"; label: "Next track"
                        available: root.player !== null && root.player.canGoNext
                        onActivated: root.player.next()
                    }
                }
            }
        }
    }
}
