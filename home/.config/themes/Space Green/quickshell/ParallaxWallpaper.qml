import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root
    property bool enabled: true
    property real previewPosition: -1
    IpcHandler {
        target: "parallax"
        function enable(value: bool): void { root.enabled = value; }
        function preview(position: real): void { root.previewPosition = position; }
        function status(): string {
            return JSON.stringify({enabled: root.enabled, preview: root.previewPosition,
                workspace: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 0});
        }
    }
    Variants {
        model: Quickshell.screens
        PanelWindow {
            id: wallpaper
            required property var modelData
            screen: modelData
            visible: root.enabled
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            exclusiveZone: -1
            color: "#030a10"
            mask: Region {}
            WlrLayershell.layer: WlrLayer.Background
            WlrLayershell.namespace: "space-green-parallax"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            readonly property var hyprMonitor: Hyprland.monitorFor(screen)
            readonly property int workspaceId: hyprMonitor && hyprMonitor.activeWorkspace ? hyprMonitor.activeWorkspace.id : 3
            // Five primary workspaces span the camera travel. Further IDs clamp
            // to the edge so they can never uncover the image's outer boundary.
            property real camera: root.previewPosition >= 0 ? Math.max(-1, Math.min(1, (root.previewPosition - 3) / 2)) : Math.max(-1, Math.min(1, (workspaceId - 3) / 2))
            Behavior on camera { NumberAnimation { duration: 420; easing.type: Easing.OutQuint } }
            Item {
                anchors.fill: parent
                clip: true
                Repeater {
                    model: [
                        {file: "background.png", travel: 0.004, tilt: 0.15},
                        {file: "middle-clean.png", travel: 0.012, tilt: 0.32},
                        {file: "foreground.png", travel: 0.028, tilt: 0.85}
                    ]
                    Image {
                        id: plane
                        required property var modelData
                        readonly property real cover: Math.max(wallpaper.width / 1667, wallpaper.height / 943) * 1.08
                        width: 1667 * cover
                        height: 943 * cover
                        x: (wallpaper.width - width) / 2 - wallpaper.camera * wallpaper.width * modelData.travel
                        y: (wallpaper.height - height) / 2
                        source: "file://" + Quickshell.env("HOME") + "/.config/themes/Space Green/parallax/" + modelData.file
                        smooth: true
                        mipmap: true
                        transform: Rotation {
                            origin.x: plane.width / 2
                            origin.y: plane.height / 2
                            axis { x: 0; y: 1; z: 0 }
                            angle: -wallpaper.camera * modelData.tilt
                        }
                    }
                }
            }
        }
    }
}
