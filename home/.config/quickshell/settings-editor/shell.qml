import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

ShellRoot {
    id: root
    property var config: ({shared: {}, themes: {}, layout: {}})
    property bool creatorMode: Quickshell.env("QUICKSHELL_SETTINGS_PAGE") === "creator"
    property string selectedScope: "themes"
    property string selectedTheme: ""
    property string selectedComponent: "shell"
    property string filter: ""
    property string message: "Select an element to adjust its settings."
    property bool failed: false
    readonly property var groups: selectedScope === "shared" ? config.shared : selectedScope === "layout" ? config.layout : (config.themes[selectedTheme] || {})
    readonly property var values: groups[selectedComponent] || {}
    onSelectedThemeChanged: { Qt.callLater(function() { if (!Object.keys(root.groups).includes(root.selectedComponent)) root.selectedComponent = Object.keys(root.groups)[0] || ""; }); }
    function label(key) {
        const names = {Visibility: "Show / hide widgets", shell: "Desktop & widget frames", CpuWidget: "CPU", TempWidget: "Temperature", MemoryWidget: "Memory", NetworkWidget: "Network", MediaPanel: "Spotify", DesktopUi: "Desktop bar", AppLauncher: "App launcher", DesktopNotifications: "Notifications", PowerMenu: "Power menu", UiButton: "Buttons", WidgetLayout: "Snapping & geometry", MovableWidget: "Widget frames", Glass: "Glass surfaces", Graph: "Graphs", SystemMonitor: "Monitoring", cpu: "CPU position", temperature: "Temperature position", memory: "Memory position", network: "Network position", spotify: "Spotify position"};
        return names[key] || key;
    }
    function fieldLabel(key) {
        if (selectedComponent === "shell" && /^implicit(Width|Height)/.test(key)) {
            const index = Number(key.split("_")[1] || 1) - 1;
            return ["CPU", "Temperature", "Memory", "Network"][index] + (key.includes("Width") ? " width" : " height");
        }
        if (selectedComponent === "shell" && /^(panelColor|edgeColor|textColor|accentColor|panelOpacity|cornerRadius|edgeWidth)/.test(key)) {
            const index = Number(key.split("_")[1] || 1) - 1;
            return ["Spotify", "Power menu", "Desktop bar"][index] + " · " + key.split("_")[0].replace(/([A-Z])/g, " $1").toLowerCase();
        }
        return key.replace(/_/g, " · ").replace(/([A-Z])/g, " $1").replace(/\./g, " ");
    }
    function refresh() {
        try { config = JSON.parse(storage.text()); } catch (error) { failed = true; message = "Cannot read settings: " + error; }
        Qt.callLater(function() { if (!Object.keys(root.groups).includes(root.selectedComponent)) root.selectedComponent = Object.keys(root.groups)[0] || ""; });
    }
    function edit(key, value, reset) {
        if (writer.running) return;
        const request = {path: [selectedScope, selectedComponent, key], theme: selectedTheme, expected: values[key], value: value};
        writer.command = ["python3", Quickshell.env("HOME") + "/.config/quickshell/settings-editor/backend.py", reset ? "reset" : "patch", JSON.stringify(request)];
        writer.running = true;
    }
    FileView {
        id: storage
        path: Quickshell.env("HOME") + "/.config/quickshell/settings.json"
        blockLoading: true; watchChanges: true
        onLoaded: root.refresh()
        onFileChanged: reload()
    }
    Process {
        id: themeReader
        command: ["python3", Quickshell.env("HOME") + "/.config/quickshell/settings-editor/backend.py", "info"]
        running: true
        stdout: StdioCollector { onStreamFinished: { try { const theme = JSON.parse(text).theme; root.selectedTheme = root.config.themes[theme] ? theme : Object.keys(root.config.themes)[0]; if (!root.config.themes[theme]) root.creatorMode = true; } catch (e) {} } }
    }
    Process {
        id: writer
        stdout: StdioCollector { onStreamFinished: {
            try { const result = JSON.parse(text); root.failed = !result.ok; root.message = result.message; storage.reload(); }
            catch (error) { root.failed = true; root.message = "Could not save settings."; }
        } }
    }
    IpcHandler { target: "settingsEditor"; function show(): void { window.show(); window.raise(); window.requestActivate(); } function creator(): void { root.creatorMode=true; window.show(); window.raise(); window.requestActivate(); } function creatorSection(section: string): void { if (creator.sections.includes(section)) { root.creatorMode = true; creator.section = section; } } function creatorState(): string { return JSON.stringify({visible:root.creatorMode,width:creator.width,height:creator.height,windowWidth:window.width,windowHeight:window.height,loaded:creator.loadedName,fields:creator.schema.length,busy:creator.busy,message:creator.message}); } }
    ApplicationWindow {
        id: window
        visible: true; width: Math.min(1180, Screen.width - 60); height: Math.min(800, Screen.height - 80); minimumWidth: 740; minimumHeight: 500
        title: "Quickshell Settings"
        color: "#10181d"
        palette { window: "#10181d"; windowText: "#e8eef0"; base: "#1c282f"; text: "#e8eef0"; button: "#25343c"; buttonText: "#e8eef0"; highlight: "#78c5ad"; highlightedText: "#10181d" }
        onClosing: Qt.quit()
        ColumnLayout {
            anchors.fill: parent; anchors.margins: 24; spacing: 16
            RowLayout {
                ColumnLayout {
                    spacing: 4
                    Label { text: "Quickshell Settings"; font.pixelSize: 26; font.bold: true }
                    Label { text: "Your desktop, one element at a time."; color: "#a6b9c2" }
                }
                Item { Layout.fillWidth: true }
                Button { text: root.creatorMode ? "Element settings" : "Theme Creator"; onClicked: root.creatorMode = !root.creatorMode }
                Button { visible: !root.creatorMode; text: "Refresh"; onClicked: storage.reload() }
            }
            ThemeCreator { id: creator; visible: root.creatorMode; Layout.fillWidth: true; Layout.fillHeight: true }
            RowLayout {
                visible: !root.creatorMode
                Label { text: "Settings for" }
                ComboBox {
                    Layout.preferredWidth: 195
                    model: ["Theme appearance", "Shared components", "Widget positions"]
                    onActivated: { root.selectedScope = ["themes", "shared", "layout"][currentIndex]; root.selectedComponent = Object.keys(root.groups)[0] || ""; }
                }
                ComboBox {
                    visible: root.selectedScope === "themes"
                    model: Object.keys(root.config.themes)
                    currentIndex: model.indexOf(root.selectedTheme)
                    onActivated: { root.selectedTheme = currentText; root.selectedComponent = Object.keys(root.groups)[0] || ""; }
                    Layout.preferredWidth: 180
                }
                Item { Layout.fillWidth: true }
                TextField { placeholderText: "Find a setting…"; placeholderTextColor: "#a6b9c2"; onTextChanged: root.filter = text.toLowerCase(); Layout.preferredWidth: 200 }
            }
            RowLayout {
                visible: !root.creatorMode
                Layout.fillWidth: true; Layout.fillHeight: true; spacing: 20
                Rectangle {
                    Layout.preferredWidth: 215; Layout.fillHeight: true; color: "#172229"; radius: 12
                    ListView {
                        anchors.fill: parent; anchors.margins: 8; spacing: 4; clip: true
                        model: Object.keys(root.groups)
                        delegate: ItemDelegate {
                            required property string modelData
                            width: ListView.view.width; text: root.label(modelData)
                            highlighted: root.selectedComponent === modelData
                            onClicked: { root.selectedComponent = modelData; root.filter = ""; }
                        }
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true; Layout.fillHeight: true; spacing: 8
                    Label { text: root.label(root.selectedComponent); font.pixelSize: 21; font.bold: true }
                    Label { text: root.selectedScope === "shared" ? "Used across all themes. Theme-specific values can override shared defaults." : root.selectedScope === "layout" ? "Positions are shared across themes. Dragging widgets also updates these values." : "Changes affect this theme. Select the active theme to see them on your desktop."; wrapMode: Text.WordWrap; Layout.fillWidth: true; color: "#a6b9c2" }
                    ScrollView {
                        Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                        contentWidth: availableWidth
                        ColumnLayout {
                            width: parent.width; spacing: 8
                            Repeater {
                                model: Object.keys(root.values).filter(k => !root.filter || root.fieldLabel(k).toLowerCase().includes(root.filter))
                                delegate: Rectangle {
                                    id: row
                                    required property string modelData
                                    readonly property var value: root.values[modelData]
                                    readonly property bool numeric: typeof value === "number"
                                    readonly property bool boolean: typeof value === "boolean"
                                    Layout.fillWidth: true; implicitHeight: 82; radius: 8; color: "#172229"
                                    RowLayout {
                                        anchors.fill: parent; anchors.margins: 12; spacing: 10
                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            Label { text: root.fieldLabel(row.modelData); font.pixelSize: 14 }
                                            Label { text: row.modelData.toLowerCase().includes("opacity") ? "0 = transparent · 1 = opaque" : row.modelData === "interval" ? "Milliseconds" : typeof row.value === "string" && row.value.startsWith("#") ? "#RRGGBB or #AARRGGBB" : ""; visible: text.length > 0; font.pixelSize: 10; color: "#849ca8" }
                                        }
                                        Rectangle { visible: typeof row.value === "string" && row.value.startsWith("#"); width: 26; height: 26; radius: 5; color: visible ? row.value : "transparent"; border.color: "#a6b9c2" }
                                        Switch { visible: row.boolean; checked: row.boolean ? row.value : false; enabled: !writer.running; onClicked: root.edit(row.modelData, checked, false) }
                                        TextField {
                                            id: input
                                            visible: !row.boolean; Layout.preferredWidth: 150
                                            text: String(row.value)
                                            enabled: !writer.running
                                            onAccepted: apply.clicked()
                                        }
                                        Button {
                                            id: apply
                                            visible: !row.boolean; text: "Apply"; enabled: !writer.running && input.text !== String(row.value)
                                            onClicked: {
                                                if (row.numeric && (!input.text.trim() || !Number.isFinite(Number(input.text)))) { root.failed = true; root.message = "Enter a valid number."; return; }
                                                root.edit(row.modelData, row.numeric ? Number(input.text) : input.text, false);
                                            }
                                        }
                                        Button { text: "Reset"; enabled: !writer.running; onClicked: root.edit(row.modelData, row.value, true); ToolTip.visible: hovered; ToolTip.text: "Restore the value from when this editor was created" }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            Label { visible: !root.creatorMode; text: root.message; color: root.failed ? "#ff9c96" : "#8fd3b6"; wrapMode: Text.WordWrap; Layout.fillWidth: true }
            Label { visible: !root.creatorMode; text: "Each saved change has a backup. Reset restores the original value for this editor."; font.pixelSize: 11; color: "#849ca8" }
        }
    }
    Component.onCompleted: refresh()
}
