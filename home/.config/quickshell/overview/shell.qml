import QtQuick
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
    property real reveal: 0
    property bool closing: false
    property bool themeReady: false
    property int pendingWorkspace: -1
    function openWhenReady() {
        if (rows.length && themeReady && !closing && reveal === 0) {
            transition.to = 1;
            transition.start();
        }
    }
    function dismiss() {
        if (closing) return;
        closing = true;
        transition.stop();
        transition.to = 0;
        transition.start();
    }
    NumberAnimation {
        id: transition
        target: root; property: "reveal"
        duration: root.closing ? 180 : 260
        easing.type: Easing.OutCubic
        onFinished: {
            if (!root.closing) return;
            if (root.pendingWorkspace > 0) {
                switcher.command = ["python3", root.backend, "activate", String(root.pendingWorkspace)];
                switcher.running = true;
            } else Qt.quit();
        }
    }
    function move(dx, dy) {
        selected = Math.max(0, Math.min(rows.length-1, selected + dx + dy*columns));
        grid.positionViewAtIndex(selected, GridView.Contain);
    }
    function choose(index) {
        if (closing || switcher.running || index < 0 || index >= rows.length) return;
        pendingWorkspace = rows[index].id;
        dismiss();
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
                root.openWhenReady();
            } catch (e) { root.message = "Workspace information is unavailable. Escape closes the overview."; }
        } }
    }
    Process {
        id: themeReader
        command: ["python3", root.backend, "theme"]
        running: true
        stdout: StdioCollector { onStreamFinished: {
            try { const data = JSON.parse(text); if (data.ok) { root.theme = data.theme; root.wallpaper = data.wallpaper; } } catch(e) {}
            root.themeReady = true; root.openWhenReady();
        } }
    }
    Process {
        id: switcher
        stdout: StdioCollector { onStreamFinished: {
            try { const data = JSON.parse(text); if (data.ok) Qt.quit(); else { root.message=data.message; root.pendingWorkspace=-1; root.closing=false; root.openWhenReady(); } }
            catch(e) { root.message="Could not switch workspace."; }
        } }
    }
    Timer { interval: 1500; repeat: true; running: !root.closing; onTriggered: { if (!reader.running) reader.running=true; } }
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
                if (root.closing) { event.accepted=true; return; }
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
            Item {
                anchors.fill: parent
                opacity: root.reveal
                Image { anchors.fill:parent; source:root.wallpaper ? "file://"+root.wallpaper : ""; fillMode:Image.PreserveAspectCrop }
                Rectangle { anchors.fill:parent; color:"#bc080d13" }
            }
            MouseArea { anchors.fill:parent; enabled:!root.closing; onClicked:root.dismiss() }
            GridView {
                id:grid
                anchors.centerIn:parent
                width:parent.width*0.88
                readonly property int visibleRows: Math.min(3,Math.max(1,Math.ceil(root.rows.length/root.columns)))
                height:Math.min(parent.height*0.82, visibleRows * (cellWidth*0.5625+28))
                opacity:root.reveal
                scale:0.94+0.06*root.reveal
                enabled:!root.closing
                clip:true
                model:root.rows
                cellWidth:width/root.columns
                cellHeight:height/visibleRows
                boundsBehavior:Flickable.StopAtBounds
                delegate:Item {
                    id:card
                    required property var modelData
                    required property int index
                    width:grid.cellWidth; height:grid.cellHeight
                    transform: Translate {
                        x: card.index >= root.rows.length - (root.rows.length % root.columns)
                           ? (root.columns - root.rows.length % root.columns) * grid.cellWidth / 2 : 0
                    }
                    Item {
                        id:scene
                        anchors.centerIn:parent
                        width:Math.min(parent.width-28,(parent.height-28)*card.modelData.width/card.modelData.height)
                        height:width*card.modelData.height/card.modelData.width
                        opacity:root.selected===card.index ? 1 : 0.85
                        Behavior on opacity { NumberAnimation { duration:140 } }
                        Rectangle { anchors.fill:parent; anchors.topMargin:5; anchors.bottomMargin:-5; color:"#65000000"; radius:3 }
                        Item {
                            anchors.fill:parent
                            clip:true
                            Image { anchors.fill:parent; source:root.wallpaper ? "file://"+root.wallpaper : ""; fillMode:Image.PreserveAspectCrop }
                            Repeater {
                                model:card.modelData.windows
                                delegate:Rectangle {
                                    id:preview
                                    required property var modelData
                                    x:Math.max(0,Math.min(scene.width-24,modelData.x/card.modelData.width*scene.width))
                                    y:Math.max(0,Math.min(scene.height-18,modelData.y/card.modelData.height*scene.height))
                                    width:Math.max(24,Math.min(scene.width-x,modelData.width/card.modelData.width*scene.width))
                                    height:Math.max(18,Math.min(scene.height-y,modelData.height/card.modelData.height*scene.height))
                                    color:"#e51a2631"; radius:2; clip:true
                                    Image {
                                        anchors.centerIn:parent
                                        width:Math.min(28,parent.width*0.5); height:width
                                        source:Quickshell.iconPath(preview.modelData.app.toLowerCase(), "application-x-executable")
                                    }
                                    Loader {
                                        anchors.fill:parent
                                        active:root.previews
                                        sourceComponent:Component {
                                            ScreencopyView {
                                                captureSource:root.captureSource(preview.modelData.address)
                                                live:!root.closing
                                                paintCursor:false
                                                visible:hasContent
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        Rectangle {
                            anchors.fill:parent
                            color:"transparent"
                            border.width:1.5
                            border.color:root.accent
                            opacity:root.selected===card.index ? 0.8 : 0
                            Behavior on opacity { NumberAnimation { duration:140 } }
                        }
                        MouseArea { anchors.fill:parent; hoverEnabled:true; onPositionChanged:root.selected=card.index; onClicked:root.choose(card.index) }
                    }
                }
            }
        }
    }
}
