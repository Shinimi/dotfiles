// Music stats: how long you listened to each song and artist on Spotify, per day. Counts in 10 s steps while
// it's actually playing. Saved to ~/.local/state/musicstats/ as one small JSON file per day, never leaves this
// PC. Shown on the home screen (screen time card → Music). Off: Settings → Comfort. Made by Claude.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

Singleton {
    id: root
    readonly property bool enabled: Settings.cur("music_stats") !== false
    readonly property string dir: Quickshell.env("HOME") + "/.local/state/musicstats"
    property string day: Qt.formatDate(new Date(), "yyyy-MM-dd")
    property var today: ({})          // "artist\u001ftitle" -> [seconds, title, artist]
    property var week: ({})           // same, summed over the 6 days before today
    property bool dirty: false

    readonly property var player: Mpris.players.values.find(p => p.identity === "Spotify") || null

    Timer {
        interval: 10000; running: root.enabled; repeat: true
        onTriggered: {
            const d = Qt.formatDate(new Date(), "yyyy-MM-dd")
            if (d !== root.day) { root.save(); root.day = d; root.today = {}; root.loadWeek() }
            const p = root.player
            if (!p || !p.isPlaying || !p.trackTitle) return
            const artist = (p.trackArtist || "Unknown artist").split(",")[0].trim()
            const k = artist + "\u001f" + p.trackTitle
            const t = Object.assign({}, root.today)
            const cur = t[k] || [0, p.trackTitle, artist]
            t[k] = [cur[0] + 10, cur[1], cur[2]]
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
    function loadWeek() { if (!weekProc.running) weekProc.running = true }
    Process {
        id: weekProc
        running: true
        command: ["python3", "-I", "-c", "import json,datetime,os,sys\nd=sys.argv[1];out={}\nfor i in range(1,7):\n day=(datetime.date.today()-datetime.timedelta(days=i)).isoformat()\n try: j=json.load(open(os.path.join(d,day+'.json')))\n except Exception: continue\n for k,v in j.items():\n  o=out.setdefault(k,[0,v[1],v[2]]);o[0]+=v[0]\nprint(json.dumps(out))", root.dir]
        stdout: StdioCollector { onStreamFinished: { try { root.week = JSON.parse(this.text) } catch (e) { root.week = {} } } }
    }

    // helpers for the home screen
    readonly property var weekAll: {   // the last 6 days + today
        const w = Object.assign({}, week)
        for (const k in today) { const o = w[k] ? w[k].slice() : [0, today[k][1], today[k][2]]; o[0] += today[k][0]; w[k] = o }
        return w
    }
    function total(m) { let s = 0; for (const k in m) s += m[k][0]; return s }
    function songs(m, n) { return Object.keys(m).map(k => ({ secs: m[k][0], title: m[k][1], artist: m[k][2] })).sort((a, b) => b.secs - a.secs).slice(0, n) }
    function artists(m, n) {
        const a = {}
        for (const k in m) a[m[k][2]] = (a[m[k][2]] || 0) + m[k][0]
        return Object.keys(a).map(x => ({ name: x, secs: a[x] })).sort((p, q) => q.secs - p.secs).slice(0, n)
    }
    function fmt(s) { const h = Math.floor(s / 3600), m = Math.floor(s % 3600 / 60); return h > 0 ? h + "h " + m + "m" : m + "m" }
}
