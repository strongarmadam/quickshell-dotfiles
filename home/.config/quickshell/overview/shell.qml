import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

ShellRoot {
    id: root
    property var rows: []
    property int selected: 0
    property int activeWorkspace: 1
    property string monitorName: ""
    property string wallpaper: ""
    property string message: ""
    property string previousSnapshot: ""
    property bool previews: Quickshell.env("OVERVIEW_NO_PREVIEWS") !== "1"
    property var theme: ({panelColor:"#ee030609", textColor:"#d7f3ff", accentColor:"#3aa9d2", edgeColor:"#155779", cornerRadius:6})
    readonly property color ink: theme.textColor
    readonly property color accent: theme.accentColor
    readonly property int columns: Math.min(5, Math.max(1, Math.ceil(Math.sqrt(rows.length))))
    readonly property string backend: Quickshell.env("HOME") + "/.config/quickshell/overview/backend.py"
    function dismiss() { Qt.quit(); }
    function move(dx, dy) {
        selected = Math.max(0, Math.min(rows.length-1, selected + dx + dy*columns));
        grid.positionViewAtIndex(selected, GridView.Contain);
    }
    function choose(index) {
        if (switcher.running || index < 0 || index >= rows.length) return;
        switcher.command = ["python3", backend, "activate", String(rows[index].id)];
        switcher.running = true;
    }
    function captureSource(address) {
        const all = Hyprland.toplevels.values;
        const item = all.find(t => t.address.replace(/^0x/, "") === address.replace(/^0x/, ""));
        return item ? item.wayland : null;
    }
    Process {
        id: reader
        command: ["python3", root.backend, "snapshot"]
        running: true
        stdout: StdioCollector { onStreamFinished: {
            try {
                const data = JSON.parse(text);
                if (!data.ok) { root.message = data.message; return; }
                root.message = "";
                root.activeWorkspace = data.active;
                root.monitorName = data.monitor;
                const serialized = JSON.stringify(data.rows);
                if (root.previousSnapshot !== serialized) {
                    const oldId = root.rows[root.selected] ? root.rows[root.selected].id : data.active;
                    root.rows = data.rows;
                    root.selected = Math.max(0, root.rows.findIndex(r => r.id === oldId));
                    root.previousSnapshot = serialized;
                }
            } catch (e) { root.message = "Workspace information is unavailable. Escape closes the overview."; }
        } }
    }
    Process {
        id: themeReader
        command: ["python3", root.backend, "theme"]
        running: true
        stdout: StdioCollector { onStreamFinished: {
            try { const data = JSON.parse(text); if (data.ok) { root.theme = data.theme; root.wallpaper = data.wallpaper; } } catch(e) {}
        } }
    }
    Process {
        id: switcher
        stdout: StdioCollector { onStreamFinished: {
            try { const data = JSON.parse(text); if (data.ok) root.dismiss(); else root.message=data.message; }
            catch(e) { root.message="Could not switch workspace."; }
        } }
    }
    Timer { interval: 1500; repeat: true; running: true; onTriggered: { if (!reader.running) reader.running=true; } }
    IpcHandler {
        target: "overview"
        function toggle(): void { root.dismiss(); }
        function close(): void { root.dismiss(); }
        function navigate(dx: int, dy: int): void { root.move(dx, dy); }
        function select(): void { root.choose(root.selected); }
        function setPreviews(enabled: bool): void { root.previews=enabled; }
        function state(): string { return JSON.stringify({selected:root.rows[root.selected]?.id, active:root.activeWorkspace, workspaces:root.rows.length, windows:root.rows.reduce((n,r)=>n+r.windows.length,0), previews:root.previews, message:root.message, screen:window.screen?.name}); }
    }
    PanelWindow {
        id: window
        screen: Quickshell.screens.find(s => s.name === root.monitorName) || Quickshell.screens[0]
        anchors { top:true; bottom:true; left:true; right:true }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "quickshell-overview"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        color: "transparent"
        Item {
            anchors.fill: parent
            focus: true
            Component.onCompleted: forceActiveFocus()
            Keys.onPressed: event => {
                if (event.key===Qt.Key_Escape || (event.key===Qt.Key_W && (event.modifiers & Qt.MetaModifier))) root.dismiss();
                else if (event.key===Qt.Key_Left || event.key===Qt.Key_H) root.move(-1,0);
                else if (event.key===Qt.Key_Right || event.key===Qt.Key_L) root.move(1,0);
                else if (event.key===Qt.Key_Up || event.key===Qt.Key_K) root.move(0,-1);
                else if (event.key===Qt.Key_Down || event.key===Qt.Key_J) root.move(0,1);
                else if (event.key===Qt.Key_Return || event.key===Qt.Key_Enter || event.key===Qt.Key_Space) root.choose(root.selected);
                else if (event.key>=Qt.Key_1 && event.key<=Qt.Key_9) root.choose(root.rows.findIndex(r=>r.id===event.key-Qt.Key_0));
                else return;
                event.accepted=true;
            }
            Image { anchors.fill:parent; source:root.wallpaper ? "file://"+root.wallpaper : ""; fillMode:Image.PreserveAspectCrop }
            Rectangle { anchors.fill:parent; color:"#dc080d13" }
            MouseArea { anchors.fill:parent; onClicked:root.dismiss() }
            ColumnLayout {
                anchors.fill:parent
                anchors.margins:Math.max(24, window.width*0.045)
                spacing:18
                RowLayout {
                    Layout.fillWidth:true
                    Column {
                        spacing:5
                        Text { text:"Workspaces"; color:root.ink; font.pixelSize:28; font.bold:true }
                        Text { text:root.theme.name || "Desktop"; color:root.accent; font.pixelSize:13 }
                    }
                    Item { Layout.fillWidth:true }
                    Text { text:"← ↑ ↓ →  Navigate     Enter  Open     Esc  Close"; color:root.ink; opacity:0.7; font.pixelSize:13 }
                    Rectangle {
                        width:36; height:36; radius:18; color:closeMouse.containsMouse ? root.accent : "#20ffffff"
                        Text { anchors.centerIn:parent; text:"×"; color:root.ink; font.pixelSize:24 }
                        MouseArea { id:closeMouse; anchors.fill:parent; hoverEnabled:true; onClicked:root.dismiss() }
                    }
                }
                GridView {
                    id:grid
                    Layout.fillWidth:true; Layout.fillHeight:true
                    clip:true
                    model:root.rows
                    cellWidth:width/root.columns
                    cellHeight:Math.min(300, cellWidth*0.64+42, height/Math.min(3,Math.max(1,Math.ceil(root.rows.length/root.columns))))
                    boundsBehavior:Flickable.StopAtBounds
                    delegate:Item {
                        id:card
                        required property var modelData
                        required property int index
                        width:grid.cellWidth; height:grid.cellHeight
                        // Center an incomplete last row without changing tile size.
                        transform: Translate {
                            x: card.index >= root.rows.length - (root.rows.length % root.columns)
                               ? (root.columns - root.rows.length % root.columns) * grid.cellWidth / 2 : 0
                        }
                        Rectangle {
                            id:frame
                            anchors.fill:parent; anchors.margins:8
                            radius:Math.max(6,root.theme.cornerRadius)
                            color:root.theme.panelColor
                            border.width:root.selected===card.index ? 3 : 1
                            border.color:root.selected===card.index ? root.accent : root.theme.edgeColor
                            Item {
                                id:scene
                                anchors { horizontalCenter:parent.horizontalCenter; top:parent.top; bottom:label.top; margins:7 }
                                width:Math.min(parent.width-14,height*card.modelData.width/card.modelData.height)
                                clip:true
                                Image { anchors.fill:parent; source:root.wallpaper ? "file://"+root.wallpaper : ""; fillMode:Image.PreserveAspectCrop }
                                Rectangle { anchors.fill:parent; color:"#30000000" }
                                Text { anchors.centerIn:parent; visible:card.modelData.windows.length===0; text:"Empty workspace"; color:root.ink; opacity:0.65; font.pixelSize:13 }
                                Repeater {
                                    model:card.modelData.windows
                                    delegate:Rectangle {
                                        id:preview
                                        required property var modelData
                                        x:Math.max(0,Math.min(scene.width-24,modelData.x/card.modelData.width*scene.width))
                                        y:Math.max(0,Math.min(scene.height-18,modelData.y/card.modelData.height*scene.height))
                                        width:Math.max(24,Math.min(scene.width-x,modelData.width/card.modelData.width*scene.width))
                                        height:Math.max(18,Math.min(scene.height-y,modelData.height/card.modelData.height*scene.height))
                                        color:"#e51a2631"; border.color:root.accent; border.width:1; radius:3; clip:true
                                        Column {
                                            anchors.centerIn:parent; width:parent.width-12; spacing:4
                                            Image { anchors.horizontalCenter:parent.horizontalCenter; width:24; height:24; source:Quickshell.iconPath(preview.modelData.app.toLowerCase(), "application-x-executable") }
                                            Text { width:parent.width; text:preview.modelData.app || "Application"; color:root.ink; elide:Text.ElideRight; horizontalAlignment:Text.AlignHCenter; font.pixelSize:11 }
                                        }
                                        Loader {
                                            anchors.fill:parent; anchors.margins:1
                                            active:root.previews
                                            sourceComponent:Component {
                                                ScreencopyView {
                                                    captureSource:root.captureSource(preview.modelData.address)
                                                    live:true
                                                    paintCursor:false
                                                    visible:hasContent
                                                }
                                            }
                                        }
                                        Rectangle {
                                            anchors { left:parent.left; right:parent.right; bottom:parent.bottom }
                                            height:17; color:"#cc080d13"
                                            Text { anchors.fill:parent; anchors.leftMargin:4; text:preview.modelData.title || preview.modelData.app; color:root.ink; font.pixelSize:9; elide:Text.ElideRight; verticalAlignment:Text.AlignVCenter }
                                        }
                                    }
                                }
                            }
                            Row {
                                id:label
                                anchors { left:parent.left; right:parent.right; bottom:parent.bottom; margins:12 }
                                height:22; spacing:9
                                Rectangle { width:22; height:22; radius:5; color:root.selected===card.index ? root.accent : "#25ffffff"; Text { anchors.centerIn:parent; text:card.modelData.id; color:root.ink; font.bold:true } }
                                Text { text:(card.modelData.id===root.activeWorkspace ? "Current · " : "") + card.modelData.windows.length + (card.modelData.windows.length===1 ? " window" : " windows"); color:root.ink; font.pixelSize:12; anchors.verticalCenter:parent.verticalCenter }
                            }
                            MouseArea { anchors.fill:parent; hoverEnabled:true; onPositionChanged:root.selected=card.index; onClicked:root.choose(card.index) }
                        }
                    }
                }
                Text { Layout.fillWidth:true; text:root.message || "Choose a workspace · 1–9 to jump directly"; color:root.message ? "#ffaaaa" : root.ink; opacity:0.75; font.pixelSize:12; wrapMode:Text.Wrap }
            }
        }
    }
}
