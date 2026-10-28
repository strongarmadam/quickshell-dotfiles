import QtQuick
import QtQuick.Controls
import Quickshell

// Draw inside the bar's existing, fixed-size surface, just like AppLauncher.
Item {
    id: root
    required property var palette
    required property date today
    property var screen: null
    property bool opened: false
    property bool presented: false
    property int viewYear: today.getFullYear()
    property int viewMonth: today.getMonth()
    readonly property int firstOffset: (new Date(viewYear, viewMonth, 1).getDay() + 6) % 7
    readonly property real revealProgress: sheet.reveal
    visible: presented
    enabled: opened
    x: parent ? (parent.width - width) / 2 : 0
    y: 38
    width: Math.min(340 + 2 * palette.cornerRadius, screen ? screen.width - 32 : 340)
    height: 352

    function resetMonth() {
        viewYear = today.getFullYear();
        viewMonth = today.getMonth();
    }
    function changeMonth(offset) {
        const date = new Date(viewYear, viewMonth + offset, 1);
        viewYear = date.getFullYear();
        viewMonth = date.getMonth();
    }
    function open(targetScreen) { screen = targetScreen; resetMonth(); opened = true; }
    function close() { opened = false; }
    function hideImmediately() {
        close();
        openingTimer.stop();
        revealAnimation.stop();
        sheet.reveal = 0;
        presented = false;
    }
    function animateTo(target) {
        revealAnimation.stop();
        revealAnimation.from = sheet.reveal;
        revealAnimation.to = target;
        revealAnimation.start();
    }
    onOpenedChanged: {
        if (opened) {
            if (!presented) {
                presented = true;
                openingTimer.restart();
            } else animateTo(1);
            Qt.callLater(() => { if (root.opened) root.forceActiveFocus(); });
        } else {
            openingTimer.stop();
            animateTo(0);
        }
    }
    Keys.onEscapePressed: close()
    Keys.onLeftPressed: changeMonth(-1)
    Keys.onRightPressed: changeMonth(1)
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Home) resetMonth();
        else if (event.key === Qt.Key_PageUp) changeMonth(-1);
        else if (event.key === Qt.Key_PageDown) changeMonth(1);
        else return;
        event.accepted = true;
    }
    Timer { id: openingTimer; interval: 32; onTriggered: if (root.opened) root.animateTo(1) }
    NumberAnimation {
        id: revealAnimation
        target: sheet; property: "reveal"
        duration: 160; easing.type: Easing.OutCubic
        onFinished: if (!root.opened) root.presented = false
    }
    Item {
        anchors.fill: parent
        clip: true
        Item {
            id: sheet
            property real reveal: 0
            width: parent.width; height: parent.height
            y: (reveal - 1) * height
            // Transparent bars have no dropdown fill. Use the launcher item
            // surface here, inside the same clipped, animated sheet.
            Rectangle {
                anchors.fill: parent
                anchors.leftMargin: root.palette.cornerRadius
                anchors.rightMargin: root.palette.cornerRadius
                visible: root.palette.barBackground.a === 0
                color: root.palette.surfaceColor
                radius: root.palette.cornerRadius
                border.width: Math.max(1, root.palette.edgeWidth)
                border.color: root.palette.edgeColor
            }
            Column {
                anchors { fill: parent; topMargin: 12; bottomMargin: 12; leftMargin: 12 + root.palette.cornerRadius; rightMargin: 12 + root.palette.cornerRadius }
                spacing: 8
                Row {
                    width: parent.width; height: 32
                    CalendarButton { width: 32; text: "‹"; accessibleLabel: "Previous month"; onClicked: root.changeMonth(-1) }
                    Text {
                        width: parent.width - 64; height: 32
                        text: Qt.formatDate(new Date(root.viewYear, root.viewMonth, 1), "MMMM yyyy")
                        color: root.palette.textColor
                        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                        font { family: "JetBrainsMono Nerd Font"; pixelSize: 15; bold: true }
                    }
                    CalendarButton { width: 32; text: "›"; accessibleLabel: "Next month"; onClicked: root.changeMonth(1) }
                }
                Row {
                    width: parent.width; height: 24
                    Repeater {
                        model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
                        Text {
                            required property string modelData
                            width: parent.width / 7; height: 24
                            text: modelData; color: root.palette.accentColor
                            horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                            font { family: "JetBrainsMono Nerd Font"; pixelSize: 12; bold: true }
                        }
                    }
                }
                Grid {
                    width: parent.width; height: 216
                    columns: 7
                    Repeater {
                        model: 42
                        Rectangle {
                            required property int index
                            readonly property date day: new Date(root.viewYear, root.viewMonth, index - root.firstOffset + 1)
                            readonly property bool isToday: day.getFullYear() === root.today.getFullYear() && day.getMonth() === root.today.getMonth() && day.getDate() === root.today.getDate()
                            width: parent.width / 7; height: 36
                            radius: root.palette.cornerRadius > 0 ? 7 : 0
                            color: isToday ? root.palette.accentColor : "transparent"
                            Text {
                                anchors.centerIn: parent
                                text: parent.day.getDate()
                                color: parent.isToday ? root.palette.panelColor : root.palette.textColor
                                opacity: parent.day.getMonth() === root.viewMonth ? 1 : 0.35
                                font { family: "JetBrainsMono Nerd Font"; pixelSize: 13; bold: parent.isToday }
                            }
                        }
                    }
                }
                CalendarButton { width: parent.width; text: "Today · " + Qt.formatDate(root.today, "ddd, d MMM"); accessibleLabel: "Return to current month"; onClicked: root.resetMonth() }
            }
        }
    }
    component CalendarButton: Button {
        id: button
        property string accessibleLabel: text
        height: 32
        Accessible.name: accessibleLabel
        focusPolicy: Qt.TabFocus
        background: Rectangle {
            color: button.hovered || button.activeFocus ? "#30ffffff" : "#14ffffff"
            radius: root.palette.cornerRadius > 0 ? 6 : 0
            border.width: button.activeFocus ? 1 : 0
            border.color: root.palette.accentColor
        }
        contentItem: Text {
            text: button.text; color: root.palette.textColor
            horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
            font { family: "JetBrainsMono Nerd Font"; pixelSize: 12; bold: true }
        }
    }
}
