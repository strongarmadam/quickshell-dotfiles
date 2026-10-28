import QtQuick

Canvas {
    id: graph

    property var values: []
    property real minimum: 0
    property real maximum: 100
    property color lineColor: "#dfb88e"

    onPaint: {
        var ctx = getContext("2d")
        ctx.clearRect(0, 0, width, height)

        if (!values || values.length < 2)
            return

        var range = maximum - minimum
        if (range <= 0)
            return

        ctx.beginPath()

        for (var i = 0; i < values.length; i++) {
            var x = 1 + i / (values.length - 1) * (width - 2)
            var normalized =
                (values[i] - minimum) / range

            normalized = Math.max(0, Math.min(1, normalized))

            var y = height - 1 - normalized * (height - 2)

            if (i === 0)
                ctx.moveTo(x, y)
            else
                ctx.lineTo(x, y)
        }

        ctx.strokeStyle = lineColor
        ctx.lineWidth = 2
        ctx.lineCap = "round"
        ctx.lineJoin = "round"
        ctx.stroke()
    }

    onValuesChanged: requestPaint()
    onMinimumChanged: requestPaint()
    onMaximumChanged: requestPaint()
    onLineColorChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
}
