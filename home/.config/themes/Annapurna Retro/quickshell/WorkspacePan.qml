import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root
    IpcHandler {
        target: "workspacePan"
        function status(): string { return JSON.stringify(Hyprland.monitors.values.map(m => ({monitor: m.name, workspace: m.activeWorkspace ? m.activeWorkspace.id : 0}))); }
    }
    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: wallpaper
            required property var modelData
            screen: modelData
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            exclusiveZone: -1
            color: "transparent"
            mask: Region {}
            WlrLayershell.layer: WlrLayer.Background
            WlrLayershell.namespace: "workspace-pan-wallpaper"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            readonly property var hyprMonitor: Hyprland.monitorFor(screen)
            readonly property int workspaceId: hyprMonitor && hyprMonitor.activeWorkspace ? hyprMonitor.activeWorkspace.id : 3
            property real camera: Math.max(-1, Math.min(1, (workspaceId - 3) / 2))
            Behavior on camera { NumberAnimation { duration: 420; easing.type: Easing.OutQuint } }
            Item {
                anchors.fill: parent
                clip: true
                Image {
                    // Four percent extra width allows a subtle pan without exposing edges.
                    width: wallpaper.width * 1.04
                    height: wallpaper.height
                    x: -wallpaper.width * 0.02 * (1 + wallpaper.camera)
                    y: 0
                    source: "file://" + Quickshell.env("HOME") + "/.config/themes/Annapurna Retro/wallpaper.png"
                    fillMode: Image.PreserveAspectCrop
                    verticalAlignment: Image.AlignTop
                    smooth: true
                    mipmap: true
                }
            }
        }
    }
}
