import QtQuick
import QtQuick.Effects

Item {
    id: root
    property Item wallpaper
    property color tint: "#030609"
    property color outline: "#155779"
    property real tintOpacity: 0.72
    property int cornerRadius: 12
    property int edgeWidth: 1
    property real blurAmount: 0.75
    default property alias content: foreground.data

    function positionOf(item) {
        let x = 0;
        let y = 0;
        while (item) {
            x += item.x;
            y += item.y;
            item = item.parent;
        }
        return Qt.point(x, y);
    }

    ShaderEffectSource {
        id: backdrop
        sourceItem: root.wallpaper
        sourceRect: {
            if (!root.wallpaper) return Qt.rect(0, 0, root.width, root.height);
            const pane = root.positionOf(root);
            const background = root.positionOf(root.wallpaper);
            return Qt.rect(pane.x - background.x, pane.y - background.y, root.width, root.height);
        }
        textureSize: Qt.size(Math.max(1, root.width), Math.max(1, root.height))
        live: false
        visible: false
        onSourceRectChanged: scheduleUpdate()
    }
    Rectangle {
        id: shape
        width: root.width
        height: root.height
        radius: root.cornerRadius
        color: "white"
        layer.enabled: true
        visible: false
    }
    MultiEffect {
        anchors.fill: parent
        source: backdrop
        blurEnabled: true
        blur: root.blurAmount
        blurMax: 32
        autoPaddingEnabled: false
        maskEnabled: true
        maskSource: shape
    }
    Rectangle {
        anchors.fill: parent
        radius: root.cornerRadius
        color: Qt.rgba(root.tint.r, root.tint.g, root.tint.b, root.tintOpacity)
        border.color: Qt.rgba(root.outline.r, root.outline.g, root.outline.b, 0.8)
        border.width: root.edgeWidth
    }
    Rectangle {
        x: Math.max(root.cornerRadius, root.edgeWidth + 2)
        y: root.edgeWidth + 1
        width: Math.max(0, root.width - 2 * x)
        height: 1
        color: "#ffffff"
        opacity: 0.09
    }
    Item {
        id: foreground
        anchors.fill: parent
    }
    Connections {
        target: root.wallpaper
        function onStatusChanged() { backdrop.scheduleUpdate(); }
        function onWidthChanged() { backdrop.scheduleUpdate(); }
        function onHeightChanged() { backdrop.scheduleUpdate(); }
    }
}
