// Settings: a mini desktop at the top of the Look pages (Appearance, Effects, Glass and blur). It is drawn from your
// real wallpaper and the settings you haven't applied yet: gaps, border, rounding, accent, see-through windows,
// blur, shadows, glow and dimming, so you see a change while you drag. Sizes are a bit exaggerated so 1-2 px
// changes are still visible. Made by Claude.
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Widgets

ClippingRectangle {
    id: lp
    width: parent ? parent.width : 600; height: 220; radius: 18
    color: "#0e0e0e"; border.width: 1; border.color: "#1f1f1f"

    property string wall: ""
    Process {
        running: lp.visible
        command: ["hyprctl", "hyprpaper", "listactive"]
        stdout: StdioCollector {
            onStreamFinished: {
                for (const l of this.text.split("\n")) {
                    const i = l.indexOf(" = "), j = l.indexOf(": "), k = i > 0 ? i : j
                    if (k > 0 && l.slice(0, k).trim() === "DP-1") lp.wall = l.slice(k + (i > 0 ? 3 : 2)).trim()
                }
            }
        }
    }
    readonly property string wallPath: Settings.get("wall_main") || wall

    // the settings being edited
    readonly property real gIn: Settings.get("gaps_in") * 1.2
    readonly property real gOut: Settings.get("gaps_out") * 0.9
    readonly property real bSize: Settings.get("border_size") > 0 ? Math.max(1, Settings.get("border_size")) : 0
    readonly property real round: Settings.get("rounding") * 0.8
    readonly property var accent: ({ tokyo: ["#e0e0e0", "#b0b0b0"], storm: ["#e0e0e0", "#c4c4c4"], sakura: ["#cf6b6b", "#b0b0b0"],
                                     matcha: ["#c8c8c8", "#bdbdbd"], sunset: ["#c0c0c0", "#cf6b6b"], mono: ["#eaeaea", "#7a7a7a"] })[Settings.get("accent")] || ["#eaeaea", "#7a7a7a"]
    readonly property real opA: Settings.get("opacity_active") / 100
    readonly property real opI: Settings.get("opacity_inactive") / 100
    readonly property bool blurOn: !!Settings.get("blur")
    readonly property real blurAmt: Math.min(1, Settings.get("blur_size") * Settings.get("blur_passes") / 30)

    Image { id: wp; anchors.fill: parent; source: lp.wallPath ? "file://" + lp.wallPath : ""; fillMode: Image.PreserveAspectCrop; sourceSize.width: 900; asynchronous: true }

    // the bar
    Rectangle { x: 10; y: 8; width: parent.width - 20; height: 14; radius: 7; color: "#d0101010"
        Row { anchors.centerIn: parent; spacing: 4
              Repeater { model: 5; Rectangle { width: index === 0 ? 14 : 5; height: 5; radius: 3; color: index === 0 ? "#e0e0e0" : "#666" } } } }

    Item {
        id: area
        x: lp.gOut; y: 28 + lp.gOut * 0.6
        width: lp.width - 2 * lp.gOut; height: lp.height - y - lp.gOut
        Behavior on x { NumberAnimation { duration: 140 } }
        Behavior on y { NumberAnimation { duration: 140 } }
        Behavior on width { NumberAnimation { duration: 140 } }
        Behavior on height { NumberAnimation { duration: 140 } }
        Win { active: true;  x: 0; y: 0; width: (area.width - lp.gIn) * 0.56; height: area.height }
        Win { active: false; x: (area.width - lp.gIn) * 0.56 + lp.gIn; y: 0; width: area.width - x; height: (area.height - lp.gIn) / 2 }
        Win { active: false; x: (area.width - lp.gIn) * 0.56 + lp.gIn; y: (area.height - lp.gIn) / 2 + lp.gIn; width: area.width - x; height: (area.height - lp.gIn) / 2 }
    }
    Text { anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.margins: 8; text: "Preview"; color: "#90ffffff"; font.family: Theme.font; font.pixelSize: 9
           style: Text.Outline; styleColor: "#80000000" }

    component Win: Item {
        id: w
        property bool active: false
        Behavior on x { NumberAnimation { duration: 140 } }
        Behavior on width { NumberAnimation { duration: 140 } }
        Behavior on height { NumberAnimation { duration: 140 } }
        RectangularShadow {   // shadow, and the glow around the focused window
            anchors.fill: parent; radius: lp.round
            visible: !!Settings.get("shadows") || (w.active && !!Settings.get("glow"))
            blur: w.active && Settings.get("glow") ? Settings.get("glow_range") : Settings.get("shadow_range") * 2
            spread: 0; offset.y: w.active && Settings.get("glow") ? 0 : 2
            color: w.active && Settings.get("glow") ? Qt.alpha(lp.accent[0], Settings.get("glow_strength") / 100) : "#aa000000"
        }
        ClippingRectangle {
            anchors.fill: parent; radius: lp.round; color: "transparent"
            Behavior on radius { NumberAnimation { duration: 140 } }
            MultiEffect {   // what's behind the window, blurred like Hyprland would
                readonly property point o: w.mapToItem(lp, 0, 0)
                x: -o.x; y: -o.y; width: lp.width; height: lp.height
                source: wp; blurEnabled: lp.blurOn; blur: lp.blurAmt; blurMax: 48
                brightness: lp.blurOn ? (Settings.get("blur_brightness") - 100) / 200 : 0
            }
            Rectangle { anchors.fill: parent; color: "#141414"; opacity: w.active ? lp.opA : lp.opI }
            Column {   // a pretend app: a title line and some text lines
                x: 10; y: 10; spacing: 6
                Rectangle { width: Math.min(70, w.width * 0.4); height: 5; radius: 3; color: "#9a9a9a" }
                Repeater { model: Math.max(0, Math.floor((w.height - 24) / 11))
                    Rectangle { width: Math.max(10, (w.width - 20) * (0.4 + ((index * 37) % 50) / 100)); height: 4; radius: 2; color: "#3a3a3a" } }
            }
            Rectangle { anchors.fill: parent; color: "#000000"; visible: !w.active && !!Settings.get("dim_inactive"); opacity: Settings.get("dim_strength") / 100 }
        }
        Rectangle {   // the border: the accent gradient on the focused window
            anchors.fill: parent; radius: lp.round; color: "transparent"
            border.width: lp.bSize; border.color: w.active ? lp.accent[0] : "#3a3a3a"
            Behavior on radius { NumberAnimation { duration: 140 } }
        }
    }
}
