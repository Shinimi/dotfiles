// One short line a day, in the spirit of Frieren's long walk (original lines). Made by Claude.
pragma Singleton
import QtQuick
import Quickshell

Singleton {
    readonly property var lines: [
        "a thousand years is just a long walk",
        "learn one useless spell today",
        "slow is still moving",
        "the flowers bloom where you walked",
        "remember the small things",
        "every journey ends somewhere new",
        "magic is patience, mostly",
        "the road remembers you",
        "rest is part of the journey",
        "keep the people you meet",
        "one more step, then tea",
        "the stars were here before the map"
    ]
    function today() {
        const d = new Date(), start = new Date(d.getFullYear(), 0, 0)
        return lines[Math.floor((d - start) / 86400000) % lines.length]
    }
}
