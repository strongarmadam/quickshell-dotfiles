import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import Quickshell
import Quickshell.Io

Item {
    id: root
    property var schema: []
    property var themes: []
    property var customThemes: []
    property var fonts: []
    property var gtkThemes: []
    property var iconThemes: []
    property var draft: ({})
    property string loadedName: ""
    property string themeName: ""
    property string revision: ""
    property bool custom: false
    property bool dirty: false
    property string section: "Wallpaper"
    property string message: "Choose a starting theme. Changes stay in this draft until saved."
    property bool failed: false
    property string pendingSource: ""
    property string colorKey: ""
    property string requestAction: ""
    property string search: ""
    readonly property var sections: ["Wallpaper", "Colors", "Windows", "Widgets & icons", "Typography", "GTK", "Kitty", "Terminal palette", "Matching apps"]
    readonly property bool busy: worker.running
    function setValue(key,value) { const next=Object.assign({},draft);next[key]=value;draft=next;dirty=true; }
    function run(action,args) {
        if (worker.running) return;
        requestAction=action;
        worker.command=["python3",Quickshell.env("HOME")+"/.config/quickshell/theme-creator/backend.py",action,JSON.stringify(args || {})];worker.running=true;
    }
    function choose(name) { if (dirty) { pendingSource=name; discard.open(); } else run("load",{name:name}); }
    function save(update) { run("save",{name:themeName.trim(),source:loadedName,revision:revision,values:draft,update:update}); }
    function consume(result) {
        failed=!result.ok;
        if (!result.ok) { message=result.message || "The operation failed.";return; }
        if (requestAction==="catalog") {
            schema=result.schema;themes=result.themes;customThemes=result.custom;fonts=result.fonts;gtkThemes=result.gtkThemes;iconThemes=result.iconThemes;
            if (!loadedName) Qt.callLater(()=>run("load",{name:result.current}));
        } else if (requestAction==="load" || requestAction==="save") {
            const saved=requestAction==="save";
            loadedName=result.name;custom=result.custom;revision=result.revision;draft=result.values;
            themeName=custom ? result.name : "My " + result.name;dirty=false;
            message=saved ? result.message : custom ? "Editing a custom theme. Save changes before applying." : "Start from this theme and save your own copy. The original stays intact.";
            if (saved) Qt.callLater(()=>run("catalog",{}));
        } else message=result.message || "Done.";
    }
    Process {
        id: worker
        stdout: StdioCollector { id: output }
        onExited: { try { root.consume(JSON.parse(output.text)); } catch(e) {root.failed=true;root.message="Could not read the theme operation result.";} }
    }
    Component.onCompleted: run("catalog",{})
    FileDialog {
        id: wallpaperPicker; title: "Choose a wallpaper"; nameFilters: ["Images (*.png *.jpg *.jpeg *.webp *.bmp)"]
        onAccepted: root.setValue("wallpaper",String(selectedFile))
    }
    ColorDialog {
        id: picker; title: "Choose theme color"; options: ColorDialog.NoOptions
        onAccepted: root.setValue(root.colorKey,String(selectedColor).slice(0,7))
    }
    Dialog {
        id: discard; title: "Discard unsaved theme changes?"; modal:true
        anchors.centerIn: parent; standardButtons: Dialog.Discard | Dialog.Cancel
        onDiscarded: {root.dirty=false;root.run("load",{name:root.pendingSource});}
    }
    ColumnLayout {
        anchors.fill: parent; spacing: 12
        RowLayout {
            Label { text: "Start from" }
            ComboBox { Layout.preferredWidth: 210; model: root.themes; currentIndex: model.indexOf(root.loadedName); enabled: !root.busy; onActivated: root.choose(currentText) }
            Label { text: "Theme name" }
            TextField { Layout.fillWidth: true; Layout.minimumWidth: 100; Layout.preferredWidth: 240; text: root.themeName; enabled: !root.busy; maximumLength:48; onTextEdited: {root.themeName=text;root.dirty=true;} }
        }
        RowLayout {
            Layout.fillWidth:true;Layout.fillHeight:true;spacing:14
            Rectangle {
                Layout.preferredWidth:150;Layout.fillHeight:true;radius:10;color:"#172229"
                ColumnLayout {
                    anchors.fill:parent;anchors.margins:8;spacing:4
                    Repeater { model:root.sections
                        Button { required property string modelData; Layout.fillWidth:true; text:modelData.replace("&", "&&"); flat:true; highlighted:root.section===modelData; onClicked:root.section=modelData }
                    }
                    Item { Layout.fillHeight:true }
                    Label { text:"Only this theme\nShared behavior stays unchanged.";color:"#94aab4";font.pixelSize:11;wrapMode:Text.Wrap;Layout.fillWidth:true }
                }
            }
            ColumnLayout {
                Layout.fillWidth:true;Layout.minimumWidth:260;Layout.preferredWidth:420;Layout.fillHeight:true
                RowLayout {
                    Label { text:root.section;font.pixelSize:20;font.bold:true;Layout.fillWidth:true }
                    TextField { placeholderText:"Find a control…";placeholderTextColor:"#9eb2bc";Layout.preferredWidth:150;onTextChanged:root.search=text.toLowerCase() }
                }
                ScrollView {
                    Layout.fillWidth:true;Layout.fillHeight:true;clip:true;contentWidth:availableWidth
                    ColumnLayout {
                        width:parent.width;spacing:8
                        Repeater {
                            model:root.schema.filter(f=>(root.search ? f.label.toLowerCase().includes(root.search) : f.section===root.section))
                            delegate:Rectangle {
                                required property var modelData
                                readonly property var value:root.draft[modelData.key] === undefined ? modelData.default : root.draft[modelData.key]
                                Layout.fillWidth:true;Layout.minimumWidth:0;implicitWidth:260;implicitHeight:modelData.type==="file"?112:78;radius:8;color:"#172229"
                                ColumnLayout {
                                    anchors.fill:parent;anchors.margins:10;spacing:5
                                    Label { text:modelData.label;Layout.fillWidth:true;elide:Text.ElideRight;font.pixelSize:13 }
                                    RowLayout {
                                        Layout.fillWidth:true
                                        Rectangle { visible:modelData.type==="color";width:28;height:28;radius:5;color:visible?String(value):"transparent";border.color:"#a6b9c2";MouseArea {anchors.fill:parent;onClicked:{root.colorKey=modelData.key;picker.selectedColor=value;picker.open();}} }
                                        TextField {
                                            visible:["color","text","number","file"].includes(modelData.type);Layout.fillWidth:true;Layout.minimumWidth:80;Layout.preferredWidth:160;text:String(value);enabled:!root.busy;selectByMouse:true
                                            onEditingFinished: {
                                                const next=modelData.type==="number"?Number(text):text;
                                                if (modelData.type==="number" && (!text.trim() || !Number.isFinite(next) || next<modelData.min || next>modelData.max)) {root.failed=true;root.message=modelData.label+": enter "+modelData.min+" to "+modelData.max;return;}
                                                if (String(next)!==String(value)) root.setValue(modelData.key,next);
                                            }
                                        }
                                        ComboBox {
                                            visible:modelData.type==="enum";Layout.fillWidth:true;model:modelData.options || [];currentIndex:model.indexOf(value);enabled:!root.busy
                                            onActivated:root.setValue(modelData.key,currentText)
                                        }
                                        ComboBox {
                                            visible:["font","gtkTheme","iconTheme"].includes(modelData.type);Layout.fillWidth:true;editable:true;model:modelData.type==="font" ? root.fonts : modelData.type==="gtkTheme" ? root.gtkThemes : root.iconThemes;editText:String(value);enabled:!root.busy
                                            onActivated:root.setValue(modelData.key,currentText)
                                            onAccepted:root.setValue(modelData.key,editText)
                                        }
                                        Switch { visible:modelData.type==="bool";checked:modelData.type==="bool"?value:false;enabled:!root.busy;onClicked:root.setValue(modelData.key,checked) }
                                        Button { visible:modelData.type==="file";text:"Browse…";onClicked:wallpaperPicker.open() }
                                        Button { visible:modelData.type==="color";text:"Pick…";onClicked:{root.colorKey=modelData.key;picker.selectedColor=value;picker.open();} }
                                        Label { visible:modelData.type==="number";text:modelData.min+"–"+modelData.max;color:"#8da4b0";font.pixelSize:10 }
                                    }
                                }
                            }
                        }
                        Label { visible:root.section==="GTK";text:"GTK 3/4 palettes, controls, icon theme and fonts. Reopen applications after applying; apps with their own styling may differ.";wrapMode:Text.Wrap;Layout.fillWidth:true;color:"#9eb2bc" }
                        Label { visible:root.section==="Matching apps";text:"Bundled app palettes inherit your colors. A matching login theme is also exported into the theme’s sddm folder; installing it is a separate administrator operation.";wrapMode:Text.Wrap;Layout.fillWidth:true;color:"#9eb2bc" }
                    }
                }
            }
            ColumnLayout {
                visible: root.width >= 1000; Layout.minimumWidth:240; Layout.maximumWidth:280; Layout.preferredWidth:280;Layout.fillHeight:true;spacing:10
                Label { text:"Theme preview";font.pixelSize:18;font.bold:true }
                Rectangle {
                    id: preview;Layout.fillWidth:true;Layout.preferredHeight:330;radius:10;clip:true;color:root.draft.background || "#07121d";border.color:"#405561"
                    Image { anchors.fill:parent;source:root.draft.wallpaper ? (String(root.draft.wallpaper).startsWith("file:")?root.draft.wallpaper:"file://"+root.draft.wallpaper):"";fillMode:Image.PreserveAspectCrop }
                    Rectangle { anchors.fill:parent;color:"#20000000" }
                    Rectangle {
                        x:0;y:0;width:parent.width;height:30;color:root.draft.panel || "#102635";opacity:root.draft.panelOpacity || 0.85
                        border.width:root.draft.widgetBorder || 0;border.color:root.draft.border || "#36718c"
                        Row { anchors.centerIn:parent;spacing:12;Text {text:"◆  1  2  3";color:root.draft.accent || "white"} Text {text:"12:30    ♫  ▣";color:root.draft.text || "white"} }
                    }
                    Rectangle {
                        x:10;y:48;width:88;height:72;radius:Math.min(26,root.draft.widgetRadius || 0);color:root.draft.panel || "#102635";opacity:root.draft.panelOpacity || 0.85
                        border.width:root.draft.widgetBorder || 0;border.color:root.draft.border || "#36718c"
                        Column { anchors.centerIn:parent;spacing:9;Text {text:"CPU  24%";color:root.draft.accent || "white";font.pixelSize:11} Text {text:"▁▃▂▆▃▅▂";color:root.draft.highlight || "white"} }
                    }
                    Rectangle {
                        x:110;y:48;width:parent.width-120;height:160;radius:Math.min(30,root.draft.windowRadius || 0);color:root.draft.background || "#07121d";opacity:root.draft.activeOpacity || 1
                        border.width:root.draft.windowBorder || 0;border.color:root.draft.accent || "#58b8d7"
                        Column {
                            anchors.fill:parent;anchors.margins:12;spacing:10
                            Text {text:"Your window";color:root.draft.text || "white";font.family:root.draft.fontFamily || "Sans";font.pixelSize:12}
                            Text {text:"A quieter desktop.\nMade by you.";color:root.draft.muted || "#99b4c2";font.pixelSize:11}
                            Rectangle {width:parent.width;height:26;radius:root.draft.iconShape==="Pill"?13:root.draft.iconShape==="Square"?0:Math.min(13,root.draft.buttonRadius || 0);color:root.draft.selection || "#285c78";border.color:root.draft.border || "white";border.width:root.draft.widgetBorder || 0;Text {anchors.centerIn:parent;text:"Selected";color:root.draft.text || "white";font.pixelSize:11}}
                        }
                    }
                    Rectangle {
                        x:12;y:224;width:parent.width-24;height:88;radius:Math.min(20,root.draft.windowRadius || 0);color:root.draft.background || "#07121d";opacity:root.draft.kittyOpacity || 0.88;border.color:root.draft.inactiveBorder || "#294655";border.width:root.draft.windowBorder || 0
                        Column {anchors.fill:parent;anchors.margins:12;spacing:6;Text {text:"❯ kitty";color:root.draft.accent || "white";font.family:root.draft.kittyFont || "monospace"} Text {text:"Welcome home.";color:root.draft.text || "white"} Row {spacing:4;Repeater {model:8;Rectangle {required property int index;width:20;height:10;color:root.draft["ansi"+index] || "white"}}} }
                    }
                }
                Label { text:"Illustrative preview. Blur, application styling and font rendering can vary on the desktop.";color:"#8da4b0";wrapMode:Text.Wrap;Layout.fillWidth:true;font.pixelSize:11 }
                Item {Layout.fillHeight:true}
                Label {text:root.dirty?"Unsaved changes":"Draft matches loaded theme";color:root.dirty?"#e8bd79":"#8fd3b6";Layout.fillWidth:true}
            }
        }
        Label { text:root.busy?"Working…":root.message;elide:Text.ElideRight;maximumLineCount:2;color:root.failed?"#ff9c96":"#8fd3b6";wrapMode:Text.Wrap;Layout.fillWidth:true }
        RowLayout {
            Button {text:"Reload draft";enabled:!root.busy && !!root.loadedName;onClicked:root.choose(root.loadedName)}
            Item {Layout.fillWidth:true}
            Button {text:"Save new theme";enabled:!root.busy && !!root.loadedName && root.themeName.trim()!==root.loadedName;onClicked:root.save(false)}
            Button {text:"Save changes";visible:root.custom;enabled:!root.busy && root.dirty && root.themeName.trim()===root.loadedName;onClicked:root.save(true)}
            Button {text:"Apply saved theme";enabled:!root.busy && root.custom && !root.dirty && root.themeName.trim()===root.loadedName;onClicked:root.run("apply",{name:root.loadedName})}
        }
    }
}
