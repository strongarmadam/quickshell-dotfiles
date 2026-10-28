import "." as Config
import QtQuick
import QtQuick.Shapes
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
Scope {
    id: root
    property string launcherSymbol: Config.Settings.value("shared", "DesktopUi", "launcherSymbol", "diamond")
    property real barButtonRadius: cornerRadius > 0 ? 14 : 0
    property string themeFontFamily: "JetBrainsMono Nerd Font"
    property real themeFontSize: 12
    property color buttonHoverColor: "#18aa8953"
    property real buttonCornerRadius: -1
    property bool ringAccents: false
    property bool barShown: true
    property real barProgress: barShown || appLauncher.presented || calendarPanel.presented ? 1 : 0
    Behavior on barProgress { NumberAnimation { duration: 260; easing.type: Easing.InOutCubic } }
    function toggleBar() {
        if (barShown) { dismissDropdown(); volumePanel.visible = false; }
        barShown = !barShown;
    }
    property bool pillVolumeControls: false
    property bool launcherBubbles: Config.Settings.value("shared", "DesktopUi", "launcherBubbles", false)
    property color panelColor
    property real panelOpacity: Config.Settings.value("shared", "DesktopUi", "panelOpacity", 1)
    readonly property color surfaceColor: Qt.rgba(panelColor.r, panelColor.g, panelColor.b, panelColor.a * panelOpacity)
    property color barBackground: surfaceColor
    readonly property var hiddenTrayIds: ["spotify-client", "nm-applet", "blueman", "udiskie"]
    property color edgeColor
    property color textColor
    property color clockTextColor: accentColor
    property color clockBackground: "transparent"
    property color accentColor
    property real cornerRadius: Config.Settings.value("shared", "DesktopUi", "cornerRadius", 12)
    property int edgeWidth: Config.Settings.value("shared", "DesktopUi", "edgeWidth", 1)
    required property var monitor
    readonly property string fallbackAppIcon: "file://" + Quickshell.env("HOME") + "/.config/quickshell/components/icons/generic-application.png"
    function appIconSource(appId, entry) {
        // Resolve desktop entries first, then try the app's actual Wayland ID.
        const candidates = [entry ? entry.icon : "", String(appId), String(appId).toLowerCase()];
        for (const icon of candidates) {
            if (!icon) continue;
            if (icon.startsWith("file:")) return icon;
            if (icon.startsWith("/")) return "file://" + icon;
            // Checked lookup returns an empty string rather than a missing texture.
            const found = Quickshell.iconPath(icon, true);
            if (found) return found;
        }
        return fallbackAppIcon;
    }
    readonly property var systemBattery: UPower.displayDevice
    readonly property bool hasSystemBattery: systemBattery.ready && systemBattery.isPresent
        && (systemBattery.type === UPowerDeviceType.Battery || systemBattery.type === UPowerDeviceType.Ups)
    readonly property int batteryPercent: Math.round(Math.max(0, Math.min(1, systemBattery.percentage)) * 100)
    readonly property bool batteryCharging: systemBattery.state === UPowerDeviceState.Charging
    readonly property string batteryIcon: batteryCharging ? "󰂄"
        : ["", "", "", "", ""][Math.min(4, Math.floor(batteryPercent / 20))]
    property int diskUsage: 0
    property string network: "…"
    property string networkIcon: "󰈂"
    property var sink: Pipewire.defaultAudioSink
    readonly property var outputDevices: Pipewire.nodes.values.filter(node => node.isSink && !node.isStream && node.audio)
    readonly property var audio: sink ? sink.audio : null
    PwObjectTracker { objects: root.sink ? [root.sink] : [] }
    SystemClock { id: clock; precision: SystemClock.Minutes }
    Process {
        id: disk; command: ["df", "--output=pcent", Quickshell.env("HOME")]; running: true
        stdout: StdioCollector { onStreamFinished: root.diskUsage = parseInt(text.trim().split("\n").pop()) || 0 }
    }
    Process {
        id: net; command: ["python3", Quickshell.env("HOME") + "/.config/quickshell/network/backend.py", '{"op":"status"}']; running: true
        stdout: StdioCollector { onStreamFinished: {
            try {
                const result=JSON.parse(text); if (!result.ok) { root.network="Unavailable"; root.networkIcon="󰈂"; return; }
                const state=result.status;
                const wired=state.devices.find(d => d.type==="ethernet" && d.state.startsWith("connected"));
                const wifi=state.networks.find(n => n.active);
                if (wired) { root.network=wired.connection; root.networkIcon="󰈀"; }
                else if (wifi) { root.network=wifi.ssid + " · " + wifi.signal + "%"; root.networkIcon=wifi.signal>=75 ? "󰤨" : wifi.signal>=50 ? "󰤥" : wifi.signal>=25 ? "󰤢" : "󰤟"; }
                else { root.network="Disconnected"; root.networkIcon=state.wifiAvailable ? "󰤭" : "󰈂"; }
            } catch(e) { root.network="Unavailable"; root.networkIcon="󰈂"; }
        } }
    }
    Timer { interval: 15000; running: true; repeat: true; onTriggered: { disk.running = true; net.running = true; } }
    AppLauncher { id: appLauncher; palette: root }
    CalendarPanel { id: calendarPanel; palette: root; today: clock.date }
    function dismissDropdown() {
        pendingCalendarScreen = null;
        appLauncher.close();
        calendarPanel.close();
    }
    property var pendingCalendarScreen: null
    function toggleCalendar(screen) {
        if (calendarPanel.opened) { calendarPanel.close(); return; }
        if (pendingCalendarScreen) { pendingCalendarScreen = null; return; }
        if (appLauncher.visible) {
            pendingCalendarScreen = screen;
            appLauncher.close();
        } else calendarPanel.open(screen);
    }
    Connections {
        target: appLauncher
        function onVisibleChanged() {
            if (!appLauncher.visible && root.pendingCalendarScreen) {
                const screen = root.pendingCalendarScreen;
                root.pendingCalendarScreen = null;
                calendarPanel.open(screen);
            }
        }
        function onOpenedChanged() {
            if (appLauncher.opened) {
                root.pendingCalendarScreen = null;
                calendarPanel.hideImmediately();
            }
        }
    }
    DesktopNotifications { id: alerts; palette: root }
    IpcHandler {
        target: "desktop"
        function toggleBar(): void { root.toggleBar(); }
        function appearanceState(): string { return JSON.stringify({accent:String(root.accentColor),text:String(root.textColor),radius:root.cornerRadius,font:root.themeFontFamily,buttonRadius:root.barButtonRadius}); }
        function barState(): string { return JSON.stringify({shown: root.barShown, progress: root.barProgress, reserved: root.barProgress > 0 ? 38 : 0}); }
        function calendar(): void { root.toggleCalendar(Hyprland.focusedMonitor ? Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor.name) || Quickshell.screens[0] : Quickshell.screens[0]); }
        function closeCalendar(): void { root.pendingCalendarScreen = null; calendarPanel.close(); }
        function calendarMonth(offset: int): void { calendarPanel.changeMonth(offset); }
        function calendarState(): string { return JSON.stringify({open: calendarPanel.opened, presented: calendarPanel.presented, reveal: calendarPanel.revealProgress, year: calendarPanel.viewYear, month: calendarPanel.viewMonth + 1}); }
        function launcher(): void { appLauncher.toggle("apps"); }
        function web(): void { appLauncher.toggle("web"); }
        function closeLauncher(): void { appLauncher.close(); }
        function search(query: string): void { appLauncher.open(); appLauncher.setQuery(query); }
        function workspaceState(): string { return JSON.stringify(Hyprland.workspaces.values.map(w => ({id: w.id, windows: w.toplevels.values.length}))); }
        function launcherState(): string { return appLauncher.stateInfo(); }
        function notifications(): void { alerts.toggle(); }
        function clearNotifications(): void { alerts.clear(); }
        function iconStatus(): string { return JSON.stringify(ToplevelManager.toplevels.values.map(w => { const entry = DesktopEntries.heuristicLookup(w.appId); return {appId: w.appId, desktopEntry: entry ? entry.id : "", icon: entry ? entry.icon : "", source: root.appIconSource(w.appId, entry)}; })); }
        function status(): string { return JSON.stringify({apps: DesktopEntries.applications.values.length, windows: ToplevelManager.toplevels.values.length, notifications: alerts.count, network: root.network, volume: root.audio ? Math.round(root.audio.volume * 100) : -1}); }
    }
    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: bar
            visible: root.barProgress > 0 || root.barShown || dropOpen
            required property var modelData
            screen: modelData
            anchors { top: true; left: true; right: true }
            readonly property bool hostsLauncher: appLauncher.screen && appLauncher.screen.name === bar.screen.name
            readonly property bool launcherOpen: hostsLauncher && appLauncher.visible
            readonly property bool hostsCalendar: calendarPanel.screen && calendarPanel.screen.name === bar.screen.name
            readonly property bool calendarOpen: hostsCalendar && calendarPanel.visible
            readonly property var activeDrop: calendarOpen ? calendarPanel : appLauncher
            readonly property bool dropOpen: launcherOpen || calendarOpen
            // Keep the Wayland buffer dimensions stable across open/close.
            // The input region remains limited to the header and revealed menu.
            implicitHeight: screen ? screen.height : 38
            exclusiveZone: root.barProgress > 0 ? 38 : 0; color: "transparent"
            WlrLayershell.layer: dropOpen ? WlrLayer.Top : WlrLayer.Bottom
            WlrLayershell.keyboardFocus: dropOpen && activeDrop.opened ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            Binding { target: appLauncher; property: "parent"; value: bar.contentItem; when: bar.hostsLauncher }
            Binding { target: calendarPanel; property: "parent"; value: bar.contentItem; when: bar.hostsCalendar }
            mask: Region {
                item: header
                Region {
                    width: bar.dropOpen && bar.activeDrop.opened ? bar.width : 0
                    height: bar.dropOpen && bar.activeDrop.opened ? bar.height : 0
                }
                Region {
                    x: bar.dropOpen ? bar.activeDrop.x : 0
                    y: 38
                    width: bar.dropOpen ? bar.activeDrop.width : 0
                    height: bar.dropOpen ? Math.ceil(bar.activeDrop.height * bar.activeDrop.revealProgress) : 0
                }
            }
            WlrLayershell.namespace: "quickshell-bar"
            // Preserve the stable bar buffer; only intercept presses outside the dropdown.
            MouseArea {
                anchors.fill: parent
                z: 1000
                enabled: bar.dropOpen && bar.activeDrop.opened
                acceptedButtons: Qt.AllButtons
                onPressed: event => {
                    const drop = bar.activeDrop;
                    const inside = event.y < 38 || (event.x >= drop.x && event.x < drop.x + drop.width
                            && event.y < 38 + drop.height * drop.revealProgress);
                    if (inside) event.accepted = false;
                    else root.dismissDropdown();
                }
            }
            Shape {
                id: barSurface
                y: -(Math.max(38, header.height) + 4) * (1 - root.barProgress)
                width: parent.width
                height: 38 + Math.max(appLauncher.height, calendarPanel.height)
                readonly property real borderSize: root.edgeWidth
                readonly property real edgeY: 38 - borderSize / 2
                readonly property real dropHeight: bar.dropOpen && (bar.calendarOpen || !root.launcherBubbles) ? bar.activeDrop.height * bar.activeDrop.revealProgress : 0
                readonly property real dropWidth: bar.activeDrop.width
                readonly property real leftEdge: (width - dropWidth) / 2
                readonly property real rightEdge: leftEdge + dropWidth
                readonly property real rounding: Math.min(root.cornerRadius, dropHeight / 2)
                ShapePath {
                    fillColor: root.barBackground
                    strokeColor: "transparent"
                    startX: 0; startY: barSurface.edgeY
                    PathLine { x: barSurface.leftEdge; y: barSurface.edgeY }
                    PathQuad { controlX: barSurface.leftEdge + barSurface.rounding; controlY: barSurface.edgeY; x: barSurface.leftEdge + barSurface.rounding; y: barSurface.edgeY + barSurface.rounding }
                    PathLine { x: barSurface.leftEdge + barSurface.rounding; y: barSurface.edgeY + barSurface.dropHeight - barSurface.rounding }
                    PathQuad { controlX: barSurface.leftEdge + barSurface.rounding; controlY: barSurface.edgeY + barSurface.dropHeight; x: barSurface.leftEdge + 2 * barSurface.rounding; y: barSurface.edgeY + barSurface.dropHeight }
                    PathLine { x: barSurface.rightEdge - 2 * barSurface.rounding; y: barSurface.edgeY + barSurface.dropHeight }
                    PathQuad { controlX: barSurface.rightEdge - barSurface.rounding; controlY: barSurface.edgeY + barSurface.dropHeight; x: barSurface.rightEdge - barSurface.rounding; y: barSurface.edgeY + barSurface.dropHeight - barSurface.rounding }
                    PathLine { x: barSurface.rightEdge - barSurface.rounding; y: barSurface.edgeY + barSurface.rounding }
                    PathQuad { controlX: barSurface.rightEdge - barSurface.rounding; controlY: barSurface.edgeY; x: barSurface.rightEdge; y: barSurface.edgeY }
                    PathLine { x: barSurface.width; y: barSurface.edgeY }
                    PathLine { x: barSurface.width; y: 0 }
                    PathLine { x: 0; y: 0 }
                    PathLine { x: 0; y: barSurface.edgeY }
                }
                ShapePath {
                    fillColor: "transparent"
                    strokeColor: root.barBackground.a > 0 ? root.edgeColor : "transparent"
                    strokeWidth: barSurface.borderSize
                    startX: 0; startY: barSurface.edgeY
                    PathLine { x: barSurface.leftEdge; y: barSurface.edgeY }
                    PathQuad { controlX: barSurface.leftEdge + barSurface.rounding; controlY: barSurface.edgeY; x: barSurface.leftEdge + barSurface.rounding; y: barSurface.edgeY + barSurface.rounding }
                    PathLine { x: barSurface.leftEdge + barSurface.rounding; y: barSurface.edgeY + barSurface.dropHeight - barSurface.rounding }
                    PathQuad { controlX: barSurface.leftEdge + barSurface.rounding; controlY: barSurface.edgeY + barSurface.dropHeight; x: barSurface.leftEdge + 2 * barSurface.rounding; y: barSurface.edgeY + barSurface.dropHeight }
                    PathLine { x: barSurface.rightEdge - 2 * barSurface.rounding; y: barSurface.edgeY + barSurface.dropHeight }
                    PathQuad { controlX: barSurface.rightEdge - barSurface.rounding; controlY: barSurface.edgeY + barSurface.dropHeight; x: barSurface.rightEdge - barSurface.rounding; y: barSurface.edgeY + barSurface.dropHeight - barSurface.rounding }
                    PathLine { x: barSurface.rightEdge - barSurface.rounding; y: barSurface.edgeY + barSurface.rounding }
                    PathQuad { controlX: barSurface.rightEdge - barSurface.rounding; controlY: barSurface.edgeY; x: barSurface.rightEdge; y: barSurface.edgeY }
                    PathLine { x: barSurface.width; y: barSurface.edgeY }
                }
            }
            Rectangle {
                id: header
                TapHandler {
                    property bool hadDropdown: false
                    acceptedButtons: Qt.AllButtons
                    onPressedChanged: if (pressed) hadDropdown = bar.dropOpen && bar.activeDrop.opened
                    onTapped: if (hadDropdown) root.dismissDropdown()
                }
                anchors { top: parent.top; left: parent.left; right: parent.right; topMargin: -(Math.max(38, header.height) + 4) * (1 - root.barProgress) }
                height: Config.Settings.value("shared", "DesktopUi", "height", 38)
                color: "transparent"
                Row {
                    id: left; anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: 8 }
spacing: Config.Settings.value("shared", "DesktopUi", "spacing", 4)
                    UiButton {
                        visible: false
                        palette: root; boxed: true; label: ""; tooltip: "Applications"
                        onClicked: appLauncher.toggle("apps")
                        ThemeAppIcon { anchors.centerIn: parent; width: 20; height: 20; symbol: root.launcherSymbol; ink: root.accentColor }
                    }
                    Repeater {
                        model: 5
                        UiButton {
                            required property int index
                            readonly property var workspace: Hyprland.workspaces.values.find(w => w.id === index + 1) || null
                            readonly property int windowCount: workspace ? workspace.toplevels.values.length : 0
                            palette: root; boxed: true; occupied: windowCount > 0; tooltip: "Workspace " + (index + 1) + ": " + windowCount + " open apps"; label: String(index + 1)
                            selected: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id === index + 1 : false
                            onClicked: Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/workspace-switch", String(index + 1)])
                            onScrolled: direction => Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/workspace-vim", direction > 0 ? "left" : "right"])
                        }
                    }
                    UiButton { visible: false; palette: root; boxed: true; label: "󰏘"; onClicked: Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/theme-menu"]) }
                }
                UiButton {
                    id: clockButton
                    tooltip: "Calendar"
                    onClicked: root.toggleCalendar(bar.screen)
                    palette: root; boxed: true; labelColor: root.clockTextColor
                    Binding { target: clockButton; property: "color"; value: root.clockBackground; when: root.clockBackground.a > 0 }
                    anchors.centerIn: parent; label: Qt.formatDateTime(clock.date, "ddd dd MMM  HH:mm")
                    visible: left.width + right.width + implicitWidth + 50 < bar.width
                }
                Row {
                    id: right; anchors { right: parent.right; verticalCenter: parent.verticalCenter; rightMargin: 8 }
spacing: Config.Settings.value("shared", "DesktopUi", "spacing_2", 3)
                    Repeater {
                        model: ToplevelManager.toplevels
                        Rectangle {
                            required property var modelData
                            width: 30; height: 28; radius: root.barButtonRadius; color: modelData.activated && !root.ringAccents ? Qt.tint(root.surfaceColor, "#35ffffff") : root.surfaceColor
                            border { width: Math.max(1, root.edgeWidth); color: modelData.activated ? root.accentColor : root.edgeColor }
                            readonly property var entry: DesktopEntries.heuristicLookup(modelData.appId)
                            Image {
                                anchors.centerIn: parent; width: 20; height: 20
                                sourceSize: Qt.size(32, 32)
                                readonly property string requestedSource: root.appIconSource(modelData.appId, parent.entry)
                                property bool loadFailed: false
                                source: loadFailed ? root.fallbackAppIcon : requestedSource
                                onRequestedSourceChanged: loadFailed = false
                                onStatusChanged: if (status === Image.Error && !loadFailed) loadFailed = true
                            }
                            MouseArea { anchors.fill: parent; acceptedButtons: Qt.LeftButton | Qt.MiddleButton; onClicked: event => { if (event.button === Qt.MiddleButton) modelData.close(); else modelData.activate(); } }
                        }
                    }
                    Repeater {
                        model: SystemTray.items.values.filter(item => !root.hiddenTrayIds.includes(item.id))
                        Rectangle {
                            required property var modelData
                            width: 30; height: 28; radius: root.barButtonRadius; color: root.surfaceColor
                            border { width: Math.max(1, root.edgeWidth); color: root.edgeColor }
                            Image {
                                anchors.centerIn: parent; width: 18; height: 18
                                property bool loadFailed: false
                                readonly property string requestedSource: modelData.icon
                                source: loadFailed || !requestedSource ? root.fallbackAppIcon : requestedSource
                                onRequestedSourceChanged: loadFailed = false
                                onStatusChanged: if (status === Image.Error && !loadFailed) loadFailed = true
                            }
                            MouseArea { anchors.fill: parent; acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton; onClicked: event => { if (event.button === Qt.RightButton && modelData.hasMenu) modelData.display(bar, bar.width - 50, bar.height); else if (event.button === Qt.MiddleButton) modelData.secondaryActivate(); else modelData.activate(); } }
                        }
                    }
                    UiButton { palette: root; boxed: true; implicitWidth: 55; label: "󰻠 " + Math.round(root.monitor.cpuUsage) + "%"; onClicked: Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/desktop-app", "monitor"]) }
                    UiButton { palette: root; boxed: true; label: "󰋊 " + root.diskUsage + "%"; onClicked: Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/desktop-app", "files"]) }
                    UiButton {
                        palette: root; boxed: true; implicitWidth: 30; implicitHeight: 28
                        label: root.networkIcon; tooltip: "Network connections · " + root.network
                        onClicked: Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/network-menu"])
                    }
                    UiButton { palette: root; boxed: true; label: "󰂯"; tooltip: "Bluetooth settings"; onClicked: Quickshell.execDetached([Quickshell.env("HOME") + "/.local/bin/bluetooth-menu"]) }
                    UiButton {
                        palette: root; boxed: true; label: root.audio ? (root.audio.muted ? "󰖁 Muted" : "󰕾 " + Math.round(root.audio.volume * 100) + "%") : "󰕾 —"
                        onClicked: volumePanel.visible = !volumePanel.visible
                        onMiddleClicked: if (root.audio) root.audio.muted = !root.audio.muted
                        onRightClicked: Quickshell.execDetached(["pavucontrol"])
                        onScrolled: direction => { if (root.audio) root.audio.volume = Math.max(0, Math.min(1, root.audio.volume + direction * 0.05)); }
                    }
                    UiButton { palette: root; boxed: true; label: "󰂚 " + alerts.count; onClicked: alerts.toggle() }
                    UiButton {
                        visible: root.hasSystemBattery
                        palette: root; boxed: true; implicitWidth: 34; implicitHeight: 28
                        label: root.batteryIcon
                        labelColor: root.batteryCharging || root.batteryPercent <= 20 ? root.accentColor : root.textColor
                        tooltip: "Battery: " + root.batteryPercent + "% · " + UPowerDeviceState.toString(root.systemBattery.state)
                    }
                }
            }
        }
    }
    PanelWindow {
        id: volumePanel; visible: false; screen: Quickshell.screens[0]
        anchors { top: true; right: true }
margins { top: 46; right: 12 }
        implicitWidth: 360; implicitHeight: volumeContent.implicitHeight + 32; color: "transparent"; exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "quickshell-volume"; WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        onVisibleChanged: if (visible) volumeSurface.forceActiveFocus()
        HyprlandFocusGrab {
            active: volumePanel.visible
            windows: [volumePanel]
            onCleared: volumePanel.visible = false
        }
        Rectangle {
            id: volumeSurface
            focus: true
            Keys.onEscapePressed: event => {
                volumePanel.visible = false
                event.accepted = true
            }
            anchors.fill: parent; color: root.surfaceColor; radius: root.cornerRadius; border { color: root.edgeColor; width: root.edgeWidth }
            Column {
                id: volumeContent
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
spacing: Config.Settings.value("shared", "DesktopUi", "spacing_3", 12)
                Row { spacing: 10
                    UiButton { palette: root; label: "OUTPUT VOLUME"; onClicked: if (root.audio) root.audio.muted = !root.audio.muted }
                    UiButton { palette: root; label: "×"; onClicked: volumePanel.visible = false }
                }
                Rectangle {
                    width: parent.width; height: 18; radius: root.pillVolumeControls ? 9 : 5; color: "#30ffffff"
                    Rectangle { width: parent.width * (root.audio ? Math.min(1, root.audio.volume) : 0); height: parent.height; radius: root.pillVolumeControls ? 9 : 5; color: root.accentColor }
                    MouseArea { anchors.fill: parent; onPressed: event => { if (root.audio) root.audio.volume = Math.max(0, Math.min(1, event.x / width)); }
onPositionChanged: event => { if (pressed && root.audio) root.audio.volume = Math.max(0, Math.min(1, event.x / width)); } }
                }
                UiButton { palette: root; label: root.audio && root.audio.muted ? "Unmute" : "Mute"; onClicked: if (root.audio) root.audio.muted = !root.audio.muted }
                Rectangle { width: parent.width; height: 1; color: root.edgeColor }
                Text {
                    text: "OUTPUT DEVICE"; color: root.textColor
                    font { family: "JetBrainsMono Nerd Font"; pixelSize: 12; bold: true }
                }
                ListView {
                    id: outputList
                    width: parent.width
                    height: Math.min(contentHeight, 240)
                    clip: true; spacing: 4
                    model: root.outputDevices
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                    delegate: ItemDelegate {
                        id: outputDelegate
                        required property var modelData
                        width: outputList.width; height: 44
                        readonly property bool currentOutput: root.sink === modelData
                        readonly property string deviceLabel: modelData.description || modelData.nickname || modelData.name
                        onClicked: Pipewire.preferredDefaultAudioSink = modelData
                        background: Rectangle {
                            radius: root.pillVolumeControls ? Math.min(width, height) / 2 : root.cornerRadius > 0 ? 7 : 0
                            color: outputDelegate.currentOutput || outputDelegate.hovered ? Qt.tint(root.surfaceColor, "#30ffffff") : "transparent"
                            border.width: outputDelegate.currentOutput ? 1 : 0
                            border.color: root.accentColor
                        }
                        contentItem: Text {
                            text: (outputDelegate.currentOutput ? "✓  " : "   ") + outputDelegate.deviceLabel
                            color: outputDelegate.currentOutput ? root.accentColor : root.textColor
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                            font { family: "JetBrainsMono Nerd Font"; pixelSize: 12 }
                        }
                        ToolTip.visible: hovered
                        ToolTip.text: deviceLabel
                        ToolTip.delay: 500
                    }
                }
                Text {
                    visible: root.outputDevices.length === 0
                    text: "No audio outputs available"; color: root.textColor
                    font.pixelSize: 12
                }
            }
        }
    }
}
