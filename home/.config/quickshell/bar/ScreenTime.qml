// Screen time: how long each app was the focused window, per day. Counts in 10 s steps, stops while you're
// away (2 min without input, unless a video/game keeps the screen awake). Saved to ~/.local/state/screentime/
// as one small JSON file per day, never leaves this PC. Off: Settings → Comfort. Made by Claude.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Singleton {
    id: root
    readonly property bool enabled: Settings.cur("screen_time") !== false
    readonly property string dir: Quickshell.env("HOME") + "/.local/state/screentime"
    property string day: Qt.formatDate(new Date(), "yyyy-MM-dd")
    property var today: ({})          // key -> [seconds, label]
    property var week: ({})           // same, summed over the last 7 days
    property bool dirty: false

    // what's focused, and a friendly name for it (games: their window title instead of steam_app_123)
    readonly property var active: ToplevelManager.activeToplevel
    function keyOf(t) { return t ? (t.appId || "") : "" }
    function labelOf(t) {
        if (!t) return ""
        if (/^steam_app_\d+$|^gamescope$/.test(t.appId) && t.title) return t.title
        const e = DesktopEntries.heuristicLookup(t.appId)
        return e && e.name ? e.name : t.appId
    }

    IdleMonitor { id: idle; enabled: root.enabled; timeout: 120; respectInhibitors: true }

    Timer {
        interval: 10000; running: root.enabled; repeat: true
        onTriggered: {
            const d = Qt.formatDate(new Date(), "yyyy-MM-dd")
            if (d !== root.day) { root.save(); root.day = d; root.today = {} }
            const k = root.keyOf(root.active)
            if (!k || idle.isIdle) return
            const t = Object.assign({}, root.today)
            const cur = t[k] || [0, root.labelOf(root.active)]
            t[k] = [cur[0] + 10, root.labelOf(root.active) || cur[1]]
            root.today = t; root.dirty = true
        }
    }
    Timer { interval: 60000; running: root.enabled; repeat: true; onTriggered: root.save() }
    function save() {
        if (!dirty) return
        dirty = false
        Quickshell.execDetached(["sh", "-c", "mkdir -p \"$1\" && printf '%s' \"$2\" > \"$1/$3.json\"", "sh", dir, JSON.stringify(today), day])
    }
    Process {
        running: true
        command: ["sh", "-c", "cat \"$1/$2.json\" 2>/dev/null", "sh", root.dir, root.day]
        stdout: StdioCollector { onStreamFinished: { try { const d = JSON.parse(this.text); root.today = Object.assign(d, root.today) } catch (e) {} } }
    }
    function loadWeek() { if (!weekProc.running) weekProc.running = true; if (!daysProc.running) daysProc.running = true }
    property var days: []             // [{ date, secs }] for the 6 days before today, oldest first (the bar chart)
    Process {
        id: daysProc
        command: ["python3", "-I", "-c", "import json,datetime,os,sys\nd=sys.argv[1];out=[]\nfor i in range(6,0,-1):\n day=(datetime.date.today()-datetime.timedelta(days=i)).isoformat()\n try: s=sum(v[0] for v in json.load(open(os.path.join(d,day+'.json'))).values())\n except Exception: s=0\n out.append({'date':day,'secs':s})\nprint(json.dumps(out))", root.dir]
        stdout: StdioCollector { onStreamFinished: { try { root.days = JSON.parse(this.text) } catch (e) { root.days = [] } } }
    }
    Process {
        id: weekProc
        command: ["python3", "-I", "-c", "import json,datetime,os,sys\nd=sys.argv[1];out={}\nfor i in range(1,7):\n day=(datetime.date.today()-datetime.timedelta(days=i)).isoformat()\n try: j=json.load(open(os.path.join(d,day+'.json')))\n except Exception: continue\n for k,v in j.items():\n  o=out.setdefault(k,[0,v[1]]);o[0]+=v[0]\nprint(json.dumps(out))", root.dir]
        stdout: StdioCollector { onStreamFinished: { try { root.week = JSON.parse(this.text) } catch (e) { root.week = {} } } }
    }

    // helpers for the home screen
    function total(m) { let s = 0; for (const k in m) s += m[k][0]; return s }
    function top(m, n) { return Object.keys(m).map(k => ({ key: k, secs: m[k][0], label: m[k][1] })).sort((a, b) => b.secs - a.secs).slice(0, n) }
    readonly property var weekAll: {   // the last 6 days + today
        const w = Object.assign({}, week)
        for (const k in today) { const o = w[k] ? w[k].slice() : [0, today[k][1]]; o[0] += today[k][0]; w[k] = o }
        return w
    }
    function iconOf(key) {   // an app's icon name for the panels (games get Steam's)
        if (/^steam_app_\d+$|^gamescope$/.test(key)) return "steam"
        const e = DesktopEntries.heuristicLookup(key)
        return e && e.icon ? e.icon : key
    }
    function fmt(s) { const h = Math.floor(s / 3600), m = Math.floor(s % 3600 / 60); return h > 0 ? h + "h " + m + "m" : m + "m" }
}
