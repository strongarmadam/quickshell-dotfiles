.pragma library

function clamp(value, minimum, maximum) {
    return Math.max(minimum, Math.min(Math.max(minimum, maximum), value));
}

function closest(value, candidates, distance) {
    let best = value;
    let bestDistance = distance + 0.001;
    for (const candidate of candidates) {
        const delta = Math.abs(candidate - value);
        if (delta <= distance && delta < bestDistance) {
            best = candidate;
            bestDistance = delta;
        }
    }
    return best;
}

function snap(x, y, width, height, bounds, peers, distance, gap) {
    const maxX = Math.max(bounds.left, bounds.right - width);
    const maxY = Math.max(bounds.top, bounds.bottom - height);
    x = clamp(x, bounds.left, maxX);
    y = clamp(y, bounds.top, maxY);
    const xs = [bounds.left, maxX];
    const ys = [bounds.top, maxY];
    for (const peer of peers) {
        // Only magnetize widgets that are close in the perpendicular direction.
        if (y <= peer.y + peer.height + gap + distance
                && y + height >= peer.y - gap - distance) {
            xs.push(peer.x, peer.x + peer.width - width,
                    peer.x - width - gap, peer.x + peer.width + gap);
        }
        if (x <= peer.x + peer.width + gap + distance
                && x + width >= peer.x - gap - distance) {
            ys.push(peer.y, peer.y + peer.height - height,
                    peer.y - height - gap, peer.y + peer.height + gap);
        }
    }
    return {
        x: Math.round(clamp(closest(x, xs, distance), bounds.left, maxX)),
        y: Math.round(clamp(closest(y, ys, distance), bounds.top, maxY))
    };
}
