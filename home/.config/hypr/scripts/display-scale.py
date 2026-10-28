#!/usr/bin/env python3
"""Adjust the focused output's scale while retaining its mode and position."""
import json
import math
import subprocess
import sys

direction = {"bigger": 1, "smaller": -1}[sys.argv[1]]
monitors = json.loads(subprocess.check_output(["hyprctl", "-j", "monitors"]))
monitor = next(m for m in monitors if m.get("focused"))
current = monitor["scale"]
target = min(3.0, max(0.5, current + direction * 0.10))
# Use integral logical dimensions to avoid Hyprland rejecting a scale.
divisor = math.gcd(monitor["width"], monitor["height"])
choices = [divisor / n for n in range(1, divisor * 2 + 1)
           if 0.5 <= divisor / n <= 3.0
           and (divisor / n - current) * direction > 0.001]
if not choices or abs(target - current) < 0.001:
    sys.exit(0)
scale = min(choices, key=lambda value: abs(value - target))
quote = json.dumps
code = 'hl.monitor({output=%s, mode=%s, position=%s, scale=%.9f, transform=%d})' % (
    quote(monitor["name"]),
    quote('%dx%d@%.5f' % (monitor["width"], monitor["height"], monitor["refreshRate"])),
    quote('%dx%d' % (monitor["x"], monitor["y"])),
    scale, monitor["transform"])
result = subprocess.run(["hyprctl", "eval", code], text=True, capture_output=True)
if result.returncode or "error" in result.stdout.lower():
    sys.exit(result.stderr or result.stdout)
