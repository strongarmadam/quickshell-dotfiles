import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io

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
    height: Math.min(620, screen ? screen.height - 60 : 620)
    property var calendarData: ({events: [], calendars: [], authenticated: false, message: "Connect a calendar to show events."})
    property date selectedDate: today
    property bool editing: false
    property string requestError: ""
    readonly property string selectedKey: Qt.formatDate(selectedDate, "yyyy-MM-dd")
    readonly property var dayEvents: (calendarData.events || []).filter(e => occursOn(e, selectedDate))
    readonly property var writableCalendars: (calendarData.calendars || []).filter(c => c.type === 0)
    function occursOn(event, day) {
        const key = Qt.formatDate(day, "yyyy-MM-dd");
        return event.first_day <= key && event.last_day >= key;
    }
    function hasEvents(day) { return (calendarData.events || []).some(e => occursOn(e, day)); }
    function request(data) {
        if (requestProcess.running) return;
        requestError = "";
        requestProcess.command = ["python3", Quickshell.env("HOME") + "/.local/share/quickshell-calendar/bridge.py", "request", JSON.stringify(data)];
        requestProcess.running = true;
    }
    function sync() { request({op: "sync", month: Qt.formatDate(new Date(viewYear, viewMonth, 1), "yyyy-MM")}); }
    function connectAccount() {
        Quickshell.execDetached(["kitty", "--title", "Connect a Calendar", "--hold", Quickshell.env("HOME") + "/.local/bin/calendar-connect"]);
        close();
    }
    function refreshData() {
        try {
            const previous = calendarData;
            calendarData = JSON.parse(stateFile.text());
            if (calendarData.authenticated && !calendarData.busy) requestError = "";
            if (calendarData.actionResult === "saved" && previous.actionBusy) editing = false;
        } catch (error) { /* Preserve the last snapshot during an atomic replacement. */ }
    }
    FileView {
        id: stateFile
        path: Quickshell.env("HOME") + "/.local/state/quickshell-calendar/state.json"
        watchChanges: true; blockLoading: true; printErrors: false
        onLoaded: root.refreshData()
        onFileChanged: reload()
    }
    Process {
        id: requestProcess
        stdout: StdioCollector {
            onStreamFinished: {
                try { const result = JSON.parse(text); if (!result.ok) root.requestError = result.message; }
                catch (error) { root.requestError = "Calendar service unavailable."; }
            }
        }
    }

    function resetMonth() {
        viewYear = today.getFullYear();
        viewMonth = today.getMonth();
    }
    function changeMonth(offset) {
        const date = new Date(viewYear, viewMonth + offset, 1);
        viewYear = date.getFullYear();
        viewMonth = date.getMonth();
    }
    function changeYear(offset) {
        const date = new Date(viewYear + offset, viewMonth, 1);
        viewYear = date.getFullYear();
        viewMonth = date.getMonth();
    }
    function selectDate(offsetDays) {
        const date = new Date(selectedDate.getFullYear(), selectedDate.getMonth(), selectedDate.getDate() + offsetDays);
        selectedDate = date;
        viewYear = date.getFullYear();
        viewMonth = date.getMonth();
    }
    function selectInViewMonth() {
        const day = Math.min(selectedDate.getDate(), new Date(viewYear, viewMonth + 1, 0).getDate());
        selectedDate = new Date(viewYear, viewMonth, day);
    }
    function open(targetScreen) { screen = targetScreen; resetMonth(); selectedDate = today; editing = false; opened = true; }
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
    Keys.onEscapePressed: event => { close(); event.accepted = true; }
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Left || event.key === Qt.Key_Right
                || event.key === Qt.Key_Up || event.key === Qt.Key_Down) {
            if (event.modifiers & Qt.ShiftModifier) {
                if (event.key === Qt.Key_Left) changeMonth(-1);
                else if (event.key === Qt.Key_Right) changeMonth(1);
                else if (event.key === Qt.Key_Up) changeYear(-1);
                else changeYear(1);
            } else {
                if (event.key === Qt.Key_Left) selectDate(-1);
                else if (event.key === Qt.Key_Right) selectDate(1);
                else if (event.key === Qt.Key_Up) selectDate(-7);
                else selectDate(7);
            }
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (viewYear === selectedDate.getFullYear() && viewMonth === selectedDate.getMonth()) return;
            selectInViewMonth();
        } else if (event.key === Qt.Key_Home) resetMonth();
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
                visible: root.editing
                anchors { fill: parent; margins: 12; leftMargin: 12 + root.palette.cornerRadius; rightMargin: 12 + root.palette.cornerRadius }
                spacing: 12
                Text { text: "New event · " + Qt.formatDate(root.selectedDate, "d MMM yyyy"); color: root.palette.textColor; font { pixelSize: 15; bold: true } }
                TextField { color: root.palette.textColor; background: Rectangle { color: root.palette.surfaceColor; radius: 5; border.width: 1; border.color: root.palette.edgeColor } id: titleInput; width: parent.width; height: 40; placeholderText: "Event title"; maximumLength: 300 }
                ComboBox {
                    id: calendarChoice; width: parent.width; height: 36
                    model: root.writableCalendars; textRole: "name"
                    onModelChanged: { const i = root.writableCalendars.findIndex(c => c.is_default); currentIndex = i >= 0 ? i : 0; }
                }
                CheckBox { id: allDay; text: "All day"; palette.windowText: root.palette.textColor }
                Text { text: "Start / end · " + (root.calendarData.timezone || "local time"); color: root.palette.textColor; font.pixelSize: 12 }
                Row {
                    width: parent.width; spacing: 8; enabled: !allDay.checked
                    TextField { color: root.palette.textColor; background: Rectangle { color: root.palette.surfaceColor; radius: 5; border.width: 1; border.color: root.palette.edgeColor } id: startInput; width: (parent.width - 8) / 2; height: 38; text: "09:00"; placeholderText: "HH:mm"; inputMask: "99:99" }
                    TextField { color: root.palette.textColor; background: Rectangle { color: root.palette.surfaceColor; radius: 5; border.width: 1; border.color: root.palette.edgeColor } id: endInput; width: (parent.width - 8) / 2; height: 38; text: "10:00"; placeholderText: "HH:mm"; inputMask: "99:99" }
                }
                Text { text: "Reminder"; color: root.palette.textColor; font.pixelSize: 12 }
                ComboBox { id: reminderChoice; width: parent.width; height: 36; model: ["Calendar default", "At start", "5 minutes before", "15 minutes before", "30 minutes before", "1 hour before", "1 day before", "None"] }
                Text {
                    width: parent.width
                    text: root.requestError || root.calendarData.message || ""
                    color: root.palette.textColor; font.pixelSize: 12; wrapMode: Text.Wrap; textFormat: Text.PlainText
                }
                Row {
                    width: parent.width; spacing: 8
                    CalendarButton { width: (parent.width - 8) / 2; text: "Cancel"; enabled: !root.calendarData.actionBusy; onClicked: root.editing = false }
                    CalendarButton {
                        width: (parent.width - 8) / 2; text: root.calendarData.actionBusy ? "Saving…" : "Save event"
                        enabled: !root.calendarData.actionBusy && !requestProcess.running && titleInput.text.trim().length > 0 && root.writableCalendars.length > 0
                        onClicked: root.request({op: "create", title: titleInput.text, date: root.selectedKey, start: startInput.text, end: endInput.text, allDay: allDay.checked, calendar: root.writableCalendars[calendarChoice.currentIndex].id, reminder: ["default","0m","5m","15m","30m","1h","1d","none"][reminderChoice.currentIndex]})
                    }
                }
            }
            Column {
                visible: !root.editing
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
                    width: parent.width; height: 180
                    columns: 7
                    Repeater {
                        model: 42
                        Rectangle {
                            required property int index
                            readonly property date day: new Date(root.viewYear, root.viewMonth, index - root.firstOffset + 1)
                            readonly property bool isToday: day.getFullYear() === root.today.getFullYear() && day.getMonth() === root.today.getMonth() && day.getDate() === root.today.getDate()
                            width: parent.width / 7; height: 30
                            radius: root.palette.cornerRadius > 0 ? 7 : 0
                            color: isToday ? root.palette.accentColor : "transparent"
                            border.width: Qt.formatDate(day, "yyyy-MM-dd") === root.selectedKey ? 1 : 0
                            border.color: root.palette.accentColor
                            MouseArea { anchors.fill: parent; onClicked: root.selectedDate = parent.day; cursorShape: Qt.PointingHandCursor }
                            Rectangle {
                                anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter; bottomMargin: 2 }
                                width: 4; height: 4; radius: 2
                                visible: root.hasEvents(parent.day)
                                color: parent.isToday ? root.palette.panelColor : root.palette.accentColor
                            }
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
                Row {
                    width: parent.width; spacing: 6
                    CalendarButton { width: (parent.width - 12) / 3; text: "Today"; onClicked: { root.resetMonth(); root.selectedDate = root.today; } }
                    CalendarButton { width: (parent.width - 12) / 3; text: root.calendarData.authenticated ? "Sync" : "Connect"; enabled: !root.calendarData.busy; onClicked: root.calendarData.authenticated ? root.sync() : root.connectAccount() }
                    CalendarButton { width: (parent.width - 12) / 3; text: "+ Event"; enabled: root.calendarData.authenticated && !root.calendarData.actionBusy; onClicked: { titleInput.text = ""; root.editing = true; titleInput.forceActiveFocus(); } }
                }
                Text {
                    width: parent.width; height: 26
                    text: root.requestError || root.calendarData.message || "Connect a calendar"
                    color: root.palette.textColor; opacity: 0.8
                    font.pixelSize: 11; wrapMode: Text.Wrap; maximumLineCount: 2; elide: Text.ElideRight
                    textFormat: Text.PlainText
                }
                Row {
                    width: parent.width; height: 26
                    Text { width: parent.width - 132; text: Qt.formatDate(root.selectedDate, "ddd, d MMM"); color: root.palette.accentColor; font { pixelSize: 13; bold: true } }
                    CalendarButton { width: 132; height: 24; text: root.calendarData.authenticated ? "Calendar account…" : "Connect a calendar…"; onClicked: root.connectAccount() }
                }
                ListView {
                    width: parent.width; height: Math.max(36, root.height - 394)
                    clip: true; spacing: 6; model: root.dayEvents
                    ScrollBar.vertical: ScrollBar {}
                    delegate: Rectangle {
                        required property var modelData
                        width: ListView.view.width; height: eventText.implicitHeight + 16
                        color: root.palette.surfaceColor; radius: root.palette.cornerRadius > 0 ? 7 : 0
                        border.width: 1; border.color: root.palette.edgeColor
                        Text {
                            id: eventText
                            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 8 }
                            text: (modelData.all_day ? "All day" : modelData.time_label) + "  " + (modelData.summary || "Untitled event") + "\n" + (modelData.calendar_name || "") + (modelData.location ? " · " + modelData.location : "")
                            color: root.palette.textColor; font.pixelSize: 12
                            wrapMode: Text.Wrap; textFormat: Text.PlainText
                        }
                    }
                    Text { anchors.centerIn: parent; visible: root.dayEvents.length === 0; text: root.calendarData.authenticated ? "No events on this day" : "Your calendar events will appear here"; color: root.palette.textColor; opacity: 0.6; font.pixelSize: 11 }
                }
            }
        }
    }
    component CalendarButton: Button {
        id: button
        opacity: enabled ? 1 : 0.4
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
