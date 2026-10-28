import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland

ShellRoot {
    ThemeData { id: themes }
    PanelWindow {
        id: panel
        screen: Quickshell.screens[0] || null
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "theme-carousel"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        HyprlandFocusGrab {
            active: panel.visible
            windows: [panel]
            onCleared: Qt.quit()
        }
        property real backdropOpacity: 0
        color: Qt.rgba(16 / 255, 20 / 255, 28 / 255, backdropOpacity)
        property bool navigationAnimated: false
        property bool openingStarted: false
        property int selected: themes.initialIndex
        readonly property real cardWidth: Math.min(width * 0.55, 760)
        readonly property real cardHeight: cardWidth * 0.5625
        IpcHandler {
            target: "carousel"
            function browse(direction: int): void { panel.move(direction); }
            function selectedTheme(): string { return themes.entries[panel.selected].name; }
            function close(): void { Qt.quit(); }
        }
        function move(direction) {
            selected = (selected + direction + themes.entries.length) % themes.entries.length;
        }
        function offset(index) {
            var delta = index - selected;
            var half = Math.floor(themes.entries.length / 2);
            if (delta > half) delta -= themes.entries.length;
            if (delta < -half) delta += themes.entries.length;
            return delta;
        }
        function apply() {
            Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/theme-switcher", themes.entries[selected].name]);
            Qt.quit();
        }
        ParallelAnimation {
            id: opening
            onFinished: panel.navigationAnimated = true
            NumberAnimation { target: content; property: "scale"; from: 0.72; to: 1; duration: 280; easing.type: Easing.OutCubic }
            NumberAnimation { target: content; property: "opacity"; from: 0; to: 1; duration: 200; easing.type: Easing.OutCubic }
            NumberAnimation { target: panel; property: "backdropOpacity"; from: 0; to: 0.85; duration: 240 }
        }
        // Wayland supplies the actual surface size after component construction.
        // Keep cards hidden and snap their positions until that layout is settled.
        Timer {
            interval: 120
            running: !panel.openingStarted
            repeat: true
            onTriggered: {
                if (panel.screen && panel.width === panel.screen.width && panel.height === panel.screen.height) {
                    panel.openingStarted = true;
                    opening.start();
                }
            }
        }
        Item {
            id: content
            anchors.fill: parent
            transformOrigin: Item.Center
            scale: 0.72
            opacity: 0
            focus: true
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Left || event.key === Qt.Key_Up) panel.move(-1);
                else if (event.key === Qt.Key_Right || event.key === Qt.Key_Down) panel.move(1);
                else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) panel.apply();
                else if (event.key === Qt.Key_Escape) Qt.quit();
                else return;
                event.accepted = true;
            }
            MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons; onClicked: Qt.quit() }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                y: Math.max(24, parent.height / 2 - panel.cardHeight / 2 - 92)
                text: "Choose your atmosphere"
                color: "#f6f4ef"
                font.family: "sans-serif"
                font.pixelSize: 28
                font.weight: Font.DemiBold
            }
            Repeater {
                model: themes.entries
                delegate: Item {
                    id: card
                    required property int index
                    required property var modelData
                    readonly property int distance: panel.offset(index)
                    width: panel.cardWidth
                    height: panel.cardHeight
                    x: (panel.width - width) / 2 + distance * panel.cardWidth * 0.48
                    y: (panel.height - height) / 2 + Math.abs(distance) * 16
                    z: 10 - Math.abs(distance)
                    scale: distance === 0 ? 1 : 0.78
                    opacity: Math.abs(distance) > 1 ? 0 : distance === 0 ? 1 : 0.48
                    visible: opacity > 0
                    Behavior on x { enabled: panel.navigationAnimated; NumberAnimation { duration: 230; easing.type: Easing.OutCubic } }
                    Behavior on y { enabled: panel.navigationAnimated; NumberAnimation { duration: 230; easing.type: Easing.OutCubic } }
                    Behavior on scale { enabled: panel.navigationAnimated; NumberAnimation { duration: 230; easing.type: Easing.OutCubic } }
                    Behavior on opacity { enabled: panel.navigationAnimated; NumberAnimation { duration: 230 } }
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: -5
                        color: "#141820"
                        border.color: card.distance === 0 ? "#f6f4ef" : "#5b6270"
                        border.width: card.distance === 0 ? 2 : 1
                        radius: 6
                    }
                    Image {
                        anchors.fill: parent
                        source: card.modelData.wallpaper
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        sourceSize.width: 1200
                    }
                    Rectangle {
                        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                        height: 62
                        gradient: Gradient {
                            GradientStop { position: 0; color: "#0010141c" }
                            GradientStop { position: 1; color: "#e610141c" }
                        }
                        Text {
                            anchors { left: parent.left; leftMargin: 20; bottom: parent.bottom; bottomMargin: 14 }
                            text: card.modelData.name
                            color: "white"
                            font.pixelSize: 22
                            font.weight: Font.DemiBold
                        }
                        Text {
                            anchors { right: parent.right; rightMargin: 20; bottom: parent.bottom; bottomMargin: 16 }
                            text: card.modelData.current ? "CURRENT" : ""
                            color: "#e4e7ed"
                            font.pixelSize: 11
                            font.letterSpacing: 2
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (card.distance === 0) panel.apply();
                            else panel.selected = card.index;
                        }
                        onWheel: event => panel.move(event.angleDelta.y < 0 ? 1 : -1)
                    }
                }
            }
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                y: parent.height / 2 + panel.cardHeight / 2 + 34
                spacing: 10
                Repeater {
                    model: themes.entries
                    delegate: Rectangle {
                        required property int index
                        width: panel.selected === index ? 24 : 7
                        height: 7
                        radius: 4
                        color: panel.selected === index ? "#f6f4ef" : "#6b7280"
                        Behavior on width { NumberAnimation { duration: 180 } }
                    }
                }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                y: parent.height / 2 + panel.cardHeight / 2 + 64
                text: "←  →  Browse      Enter  Apply      Esc  Cancel"
                color: "#b8bec9"
                font.pixelSize: 14
            }
        }
    }
}
