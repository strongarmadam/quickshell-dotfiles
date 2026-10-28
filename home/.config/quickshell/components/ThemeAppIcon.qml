import QtQuick
Canvas {
    id: root
    required property string symbol
    required property color ink
    onSymbolChanged: requestPaint()
    onInkChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onPaint: {
        const c = getContext("2d"); c.reset();
        c.scale(width / 16, height / 16);
        c.fillStyle = ink;
        c.beginPath();
        if (symbol === "crescent") {
            c.arc(8, 8, 6, 0, Math.PI * 2);
            c.fill();
            c.globalCompositeOperation = "destination-out";
            c.beginPath();
            c.arc(10.6, 5.7, 5.4, 0, Math.PI * 2);
            c.fill();
            c.globalCompositeOperation = "source-over";
            return;
        }
        if (symbol === "ring") {
            c.lineWidth = 1.35;
            c.strokeStyle = ink;
            c.arc(8, 8, 4.6, 0, Math.PI * 2);
            c.stroke();
            c.beginPath();
            c.globalAlpha = 0.28;
            c.lineWidth = 0.6;
            c.arc(8, 8, 5.8, 0, Math.PI * 2);
            c.stroke();
            return;
        }
        if (symbol === "circle") c.arc(8, 8, 4, 0, Math.PI * 2);
        else if (symbol === "triangle") { c.moveTo(8, 3); c.lineTo(13, 12); c.lineTo(3, 12); c.closePath(); }
        else if (symbol === "diamond") { c.moveTo(8, 2); c.lineTo(13, 8); c.lineTo(8, 14); c.lineTo(3, 8); c.closePath(); }
        else if (symbol === "bar") c.rect(3, 6, 10, 4);
        else c.rect(4, 4, 8, 8);
        c.fill();
    }
}
