import "." as Config
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "WidgetGeometry.js" as Geometry

Scope {
    id: root
    property var windows: []
    property var positions: ({})
    property var geometry: ({})
    property bool ready: false
    property bool drawerReady: false
    property bool drawerInitialized: false
    property bool monitorWidgetsShown: true
    property var monitorDefaults: ({})
    readonly property var monitorIds: ["cpu", "temperature", "memory", "network"]
    function isMonitor(widget) { return monitorIds.includes(widget.widgetId); }
    function saveDrawer() {
        if (drawerWriter.running) { drawerSavePending = true; return; }
        drawerWriter.command = ["python3", Quickshell.env("HOME") + "/.config/hypr/scripts/widget-drawer-state.py", "save",
            JSON.stringify({shown: monitorWidgetsShown, defaults: monitorDefaults})];
        drawerWriter.running = true;
    }
    property bool drawerSavePending: false
    function restoreMonitorDefaults() {
        const updated = Object.assign({}, positions);
        windows.filter(w => isMonitor(w)).forEach(w => {
            const home = monitorDefaults[w.widgetId];
            if (home) updated[w.widgetId] = home;
            else delete updated[w.widgetId];
        });
        positions = updated;
        windows.filter(w => isMonitor(w)).forEach(w => restoreWidget(w));
        Config.Settings.saveLayout(updated);
    }
    function initializeDrawer() {
        if (!ready || !drawerReady || drawerInitialized) return;
        drawerInitialized = true;
        const homes = Object.assign({}, monitorDefaults);
        windows.filter(w => isMonitor(w)).forEach(w => {
            if (!homes[w.widgetId] && w.screen) homes[w.widgetId] = {
                screen: w.screen.name, x: w.widgetX, y: w.widgetY - availableTop(w.screen)};
        });
        monitorDefaults = homes;
        if (monitorWidgetsShown) restoreMonitorDefaults();
        saveDrawer();
    }
    function toggleMonitors() {
        if (!drawerInitialized) return;
        endDrag();
        const show = !monitorWidgetsShown;
        if (show) restoreMonitorDefaults();
        else windows.filter(w => isMonitor(w)).forEach(w => widgetHidden(w));
        monitorWidgetsShown = show;
        saveDrawer();
    }
    Process {
        id: drawerReader
        command: ["python3", Quickshell.env("HOME") + "/.config/hypr/scripts/widget-drawer-state.py", "load"]
        running: true
        stdout: StdioCollector { onStreamFinished: {
            try {
                const data = JSON.parse(text);
                root.monitorDefaults = data.defaults || {};
                root.monitorWidgetsShown = data.shown !== false;
                root.drawerReady = true;
                root.initializeDrawer();
            } catch (error) { console.warn("Monitor drawer state:", error); }
        } }
    }
    Process {
        id: drawerWriter
        onExited: { if (root.drawerSavePending) { root.drawerSavePending = false; root.saveDrawer(); } }
    }
    property var draggedWidget: null
    property real grabX: 0
    property real grabY: 0
    property string hoveredWidget: ""
    readonly property int snapDistance: Config.Settings.value("16-bit Sunset", "WidgetLayout", "snapDistance", 12)
    readonly property int widgetGap: Config.Settings.value("16-bit Sunset", "WidgetLayout", "widgetGap", 8)
    function screenInfo(screen) {
        if (!screen) return {x: 0, y: 0, left: 0, top: 0, right: 0, bottom: 0};
        return geometry[screen.name] || {x: screen.x, y: screen.y, left: 0, top: 38, right: 0, bottom: 0};
    }
    function availableTop(screen) { return screenInfo(screen).top; }
    function stackTop(screen) {
        return availableTop(screen) + Math.max(0, (screen.height - availableTop(screen) - 418) / 2);
    }
    function bounds(widget) {
        const info = screenInfo(widget.screen);
        return {left: info.left, top: info.top,
                right: widget.screen.width - info.right,
                bottom: widget.screen.height - info.bottom};
    }
    function registerWidget(widget) {
        windows = windows.concat([widget]);
        if (ready) restoreWidget(widget);
    }
    function unregisterWidget(widget) {
        widgetHidden(widget);
        windows = windows.filter(w => w !== widget);
    }
    function widgetHidden(widget) {
        if (draggedWidget === widget) endDrag();
        if (hoveredWidget === widget.widgetId) hoverWidget(widget.widgetId, false);
    }
    function hoverWidget(id, hovered) {
        if (hovered) hoveredWidget = id;
        else if (hoveredWidget === id) hoveredWidget = "";
        else return;
        // The compositor chooses widget vs. native window dragging without
        // blocking its event loop or replacing normal application dragging.
        Hyprland.dispatch("function() quickshellWidgetHovered = " + JSON.stringify(hoveredWidget) + " end");
    }
    function restoreWidget(widget) {
        const saved = positions[widget.widgetId];
        if (saved) {
            const chosen = Quickshell.screens.find(s => s.name === saved.screen);
            if (chosen) widget.screen = chosen;
        }
        if (!widget.screen) return;
        const area = bounds(widget);
        const x = saved && Number.isFinite(saved.x) ? saved.x : widget.defaultX;
        const y = saved && Number.isFinite(saved.y) ? area.top + saved.y : widget.defaultY;
        widget.widgetX = Geometry.clamp(x, area.left, area.right - widget.implicitWidth);
        widget.widgetY = Geometry.clamp(y, area.top, area.bottom - widget.implicitHeight);
    }
    function persistWidget(widget) {
        const updated = Object.assign({}, positions);
        updated[widget.widgetId] = {screen: widget.screen.name,
                                   x: Math.round(widget.widgetX),
                                   y: Math.round(widget.widgetY - availableTop(widget.screen))};
        positions = updated;
        Config.Settings.saveLayout(positions);
    }
    function beginDrag(id, x, y) {
        if (draggedWidget) endDrag();
        const widget = windows.find(w => w.widgetId === id && w.visible);
        if (!widget || !ready || !widget.screen) return false;
        if (isMonitor(widget) && (!monitorWidgetsShown || widget.drawerProgress < 0.999)) return false;
        const info = screenInfo(widget.screen);
        const localX = x - info.x;
        const localY = y - info.y;
        if (localX < widget.widgetX || localX >= widget.widgetX + widget.implicitWidth
                || localY < widget.widgetY || localY >= widget.widgetY + widget.implicitHeight) return false;
        grabX = localX - widget.widgetX;
        grabY = localY - widget.widgetY;
        draggedWidget = widget;
        return true;
    }
    function moveDrag(x, y) {
        if (!draggedWidget) return;
        const widget = draggedWidget;
        const chosen = Quickshell.screens.find(s => {
            const info = screenInfo(s);
            return x >= info.x && x < info.x + s.width && y >= info.y && y < info.y + s.height;
        });
        if (chosen && chosen !== widget.screen) widget.screen = chosen;
        const info = screenInfo(widget.screen);
        const peers = windows.filter(w => w !== widget && w.visible && w.screen === widget.screen)
            .map(w => ({x: w.widgetX, y: w.widgetY, width: w.implicitWidth, height: w.implicitHeight}));
        const result = Geometry.snap(x - info.x - grabX, y - info.y - grabY,
                                     widget.implicitWidth, widget.implicitHeight,
                                     bounds(widget), peers, snapDistance, widgetGap);
        widget.widgetX = result.x;
        widget.widgetY = result.y;
    }
    function endDrag() {
        if (!draggedWidget) return;
        const widget = draggedWidget;
        draggedWidget = null;
        persistWidget(widget);
    }
    function describe() {
        return JSON.stringify(windows.map(w => ({id: w.widgetId, visible: w.visible,
            screen: w.screen ? w.screen.name : "", x: w.widgetX, y: w.widgetY,
            width: w.implicitWidth, height: w.implicitHeight, dragging: draggedWidget === w,
            drawerProgress: isMonitor(w) ? w.drawerProgress : 1, renderedX: isMonitor(w) ? w.margins.left : w.widgetX})));
    }
    function reset() {
        endDrag();
        positions = {};
        windows.forEach(w => restoreWidget(w));
        Config.Settings.saveLayout({});
    }

    Connections {
        target: Config.Settings
        function onDataChanged() {
            root.positions = Config.Settings.data.layout || {};
            if (root.ready && !root.draggedWidget) root.windows.forEach(w => root.restoreWidget(w));
        }
    }
    Component.onCompleted: {
        positions = Config.Settings.data.layout || {};
        hoverWidget("", false);
    }
    Component.onDestruction: {
        if (draggedWidget) persistWidget(draggedWidget);
        Hyprland.dispatch('function() quickshellWidgetHovered = "" end');
    }
    Process {
        id: geometryReader
        command: ["python3", Quickshell.env("HOME") + "/.local/lib/quickshell-widgets/input.py", "geometry"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const updated = JSON.parse(text);
                    if (JSON.stringify(updated) !== JSON.stringify(root.geometry) || !root.ready) {
                        root.geometry = updated;
                        root.ready = true;
                        if (!root.draggedWidget) root.windows.forEach(w => root.restoreWidget(w));
                        root.initializeDrawer();
                    }
                } catch (error) { console.warn("Widget screen geometry:", error); }
            }
        }
    }
    Timer {
        interval: Config.Settings.value("16-bit Sunset", "WidgetLayout", "interval", 2000)
        repeat: true
        running: true
        onTriggered: { if (!geometryReader.running) geometryReader.running = true; }
    }
    Process {
        id: cursorReader
        command: ["python3", "-u", Quickshell.env("HOME") + "/.local/lib/quickshell-widgets/input.py", "cursor"]
        running: root.draggedWidget !== null
        stdout: SplitParser {
            onRead: data => {
                try {
                    const position = JSON.parse(data);
                    root.moveDrag(position.x, position.y);
                } catch (error) { console.warn("Widget cursor:", error); }
            }
        }
        onExited: { if (root.draggedWidget) root.endDrag(); }
    }
    IpcHandler {
        target: "widgets"
        function beginDrag(id: string, x: real, y: real): bool { return root.beginDrag(id, x, y); }
        function moveDrag(x: real, y: real): void { root.moveDrag(x, y); }
        function endDrag(): void { root.endDrag(); }
        function describe(): string { return root.describe(); }
        function hovered(): string { return root.hoveredWidget; }
        function reset(): void { root.reset(); }
        function toggleMonitors(): void { root.toggleMonitors(); }
        function drawerState(): string { return JSON.stringify({shown: root.monitorWidgetsShown, ready: root.drawerInitialized, defaults: root.monitorDefaults}); }
    }
}
