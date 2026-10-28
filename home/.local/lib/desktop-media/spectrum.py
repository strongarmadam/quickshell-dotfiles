#!/usr/bin/env python3
"""Stream desktop audio frequency levels as JSON; never store captured audio."""
import array
import ctypes
import ctypes.util
import json
import math
import os
import select
import signal
import subprocess
import sys
import time

RATE = 48000
SIZE = 8192
HOP = 2048
CENTERS = (31.5, 50, 80, 125, 200, 315, 500, 800,
           1250, 2000, 3150, 5000, 8000, 10000, 12500, 16000)


class Spectrum:
    def __init__(self):
        self.lib = ctypes.CDLL(ctypes.util.find_library('fftw3'))
        self.input = (ctypes.c_double * SIZE)()
        self.output = ((ctypes.c_double * 2) * (SIZE // 2 + 1))()
        self.lib.fftw_plan_dft_r2c_1d.argtypes = [ctypes.c_int, ctypes.c_void_p,
                                               ctypes.c_void_p, ctypes.c_uint]
        self.lib.fftw_plan_dft_r2c_1d.restype = ctypes.c_void_p
        self.lib.fftw_execute.argtypes = [ctypes.c_void_p]
        self.lib.fftw_destroy_plan.argtypes = [ctypes.c_void_p]
        self.plan = self.lib.fftw_plan_dft_r2c_1d(SIZE, self.input, self.output, 64)
        if not self.plan:
            raise RuntimeError('Unable to create FFT plan')
        self.window = [0.5 - 0.5 * math.cos(2 * math.pi * i / (SIZE - 1))
                       for i in range(SIZE)]
        self.scale = 2 / sum(self.window)
        edges = [CENTERS[0] / math.sqrt(CENTERS[1] / CENTERS[0])]
        edges += [math.sqrt(a * b) for a, b in zip(CENTERS, CENTERS[1:])]
        edges += [min(RATE / 2, CENTERS[-1] * math.sqrt(CENTERS[-1] / CENTERS[-2]))]
        self.bins = [(max(1, math.ceil(a * SIZE / RATE)),
                      min(SIZE // 2 + 1, math.ceil(b * SIZE / RATE)))
                     for a, b in zip(edges, edges[1:])]
        self.levels = [0.0] * len(CENTERS)

    def analyze(self, samples):
        for i, (sample, window) in enumerate(zip(samples, self.window)):
            self.input[i] = sample * window
        self.lib.fftw_execute(self.plan)
        for band, (low, high) in enumerate(self.bins):
            power = sum(self.output[k][0] ** 2 + self.output[k][1] ** 2
                        for k in range(low, high))
            # Hann-window energy correction; levels use a fixed -72..0 dBFS scale.
            amplitude = math.sqrt(power / 1.5) * self.scale
            db = 20 * math.log10(max(1e-10, amplitude))
            level = min(1.0, max(0.0, (db + 72) / 72))
            old = self.levels[band]
            self.levels[band] = level if level > old else old * 0.78 + level * 0.22
        return [round(v, 4) for v in self.levels]

    def close(self):
        self.lib.fftw_destroy_plan(self.plan)


def media_stream():
    try:
        sink = subprocess.check_output(['pactl', 'get-default-sink'], text=True, timeout=2).strip()
        return (0, sink + '.monitor') if sink else None
    except (OSError, subprocess.SubprocessError):
        return None


def emit(levels, connected):
    print(json.dumps({'levels': levels, 'connected': connected}, separators=(',', ':')),
          flush=True)


def main():
    analyzer = Spectrum()
    recorder = None
    target = None
    next_lookup = 0
    pending = bytearray()
    samples = [0.0] * SIZE
    last_audio = 0
    zero = [0.0] * len(CENTERS)

    def stop_recorder():
        nonlocal recorder
        if recorder is not None:
            recorder.terminate()
            try:
                recorder.wait(timeout=1)
            except subprocess.TimeoutExpired:
                recorder.kill()
                recorder.wait()
            recorder.stdout.close()
            recorder = None

    def stop(signum, frame):
        raise SystemExit(0)

    signal.signal(signal.SIGTERM, stop)
    signal.signal(signal.SIGINT, stop)
    try:
        while True:
            now = time.monotonic()
            if now >= next_lookup:
                selected = media_stream()
                next_lookup = now + 2
                if selected != target or (recorder is not None and recorder.poll() is not None):
                    stop_recorder()
                    target = selected
                    pending.clear()
                    samples = [0.0] * SIZE
                    analyzer.levels = zero.copy()
                if target is not None and recorder is None:
                    index, sink = target
                    recorder = subprocess.Popen([
                        'parec', '--raw', '--format=float32le', '--rate=48000',
                        '--channels=2', '--latency-msec=45', '--process-time-msec=20',
                        '--client-name=Spotify Spectrum', '--stream-name=Spotify Spectrum',
                        f'--device={sink}'],
                        stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
                    os.set_blocking(recorder.stdout.fileno(), False)
            if recorder is None:
                emit(zero, False)
                time.sleep(0.2)
                continue
            ready, _, _ = select.select([recorder.stdout], [], [], 0.15)
            if ready:
                chunk = os.read(recorder.stdout.fileno(), HOP * 8 * 4)
                if not chunk:
                    stop_recorder()
                    emit(zero, False)
                    time.sleep(0.2)
                    continue
                pending.extend(chunk)
                last_audio = now
                levels = None
                while len(pending) >= HOP * 8:
                    pcm = array.array('f')
                    pcm.frombytes(pending[:HOP * 8])
                    del pending[:HOP * 8]
                    if sys.byteorder != 'little':
                        pcm.byteswap()
                    mono = [(pcm[i] + pcm[i + 1]) * 0.5 for i in range(0, len(pcm), 2)]
                    samples = samples[HOP:] + mono
                    levels = analyzer.analyze(samples)
                if levels is not None:
                    emit(levels, True)
            elif now - last_audio > 0.25:
                analyzer.levels = zero.copy()
                emit(zero, True)
    except BrokenPipeError:
        pass
    finally:
        stop_recorder()
        analyzer.close()


if __name__ == '__main__':
    main()
