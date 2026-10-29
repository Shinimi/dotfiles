// Weather: right now from wttr.in (every 20 min), and the whole week from Open-Meteo (every 30 min). Made by Claude.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    property bool ready: false
    property string place: ""
    property int temp: 0
    property int feels: 0
    property int humidity: 0
    property int wind: 0
    property string desc: ""
    property string icon: ""
    property int code: 0                     // wttr.in condition code (the living ASCII wallpaper reads rain / snow / fog from it)
    // what the sky is doing right now, 0..1, for the living ASCII wallpaper
    readonly property real rain: [176, 263, 266, 293, 296, 353].includes(code) ? 0.35 : [299, 302, 356, 281, 284, 311].includes(code) ? 0.65
                               : [305, 308, 359, 200, 386, 389, 314].includes(code) ? 1.0 : 0
    readonly property real snow: [179, 227, 323, 326, 368, 182, 185, 317, 320, 362, 365, 374, 377].includes(code) ? 0.5 : [230, 329, 332, 335, 338, 350, 371, 392, 395].includes(code) ? 1.0 : 0
    readonly property real fog: [143, 248, 260].includes(code) ? 1.0 : 0
    property var days: []

    function iconFor(code, night) {
        code = parseInt(code)
        if (code === 113) return night ? "" : ""                       // clear
        if (code === 116) return night ? "" : ""                       // partly cloudy
        if (code === 119 || code === 122) return ""                          // cloudy
        if ([143, 248, 260].includes(code)) return ""                        // fog
        if ([200, 386, 389, 392, 395].includes(code)) return ""              // thunder
        if ([179, 182, 185, 227, 230, 281, 284, 311, 314, 317, 320, 323, 326, 329, 332, 335, 338, 350, 362, 365, 368, 371, 374, 377].includes(code)) return "" // snow/sleet
        if ([176, 263, 266, 293, 296, 353].includes(code)) return ""         // showers
        return ""                                                            // rain
    }

    readonly property string where: Settings.cur("weather_place")
    onWhereChanged: Qt.callLater(() => { fetch.running = true; weekFetch.running = true })
    Process {
        id: fetch
        command: ["curl", "-sf", "--max-time", "15", "-H", "User-Agent: curl", "https://wttr.in/" + (Settings.cur("weather_place") || "37.8812,41.1351").replace(/ /g, "+") + "?format=j1"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const j = JSON.parse(this.text)
                    const c = j.current_condition[0]
                    const h = new Date().getHours()
                    temp = parseInt(c.temp_C); feels = parseInt(c.FeelsLikeC)
                    humidity = parseInt(c.humidity); wind = parseInt(c.windspeedKmph)
                    desc = c.weatherDesc[0].value.trim()
                    code = parseInt(c.weatherCode)
                    icon = iconFor(c.weatherCode, h < 6 || h >= 19)
                    place = Settings.cur("weather_label") || Settings.cur("weather_place") || "Batman Merkez"
                    days = j.weather.map(d => ({
                        date: d.date, max: parseInt(d.maxtempC), min: parseInt(d.mintempC),
                        icon: iconFor(d.hourly[4].weatherCode, false)
                    }))
                    ready = true
                } catch (e) {}
            }
        }
    }
    Timer { interval: 20 * 60 * 1000; running: true; repeat: true; triggeredOnStart: true; onTriggered: fetch.running = true }

    // ---- the whole week (Open-Meteo, free, no key): last 6 days + 7 ahead, per day and per hour.
    // week["2026-10-25"] = { code, max, min, rain, wind, uv, sunrise, sunset, hours: [{ h, temp, code, rain }] }
    property var week: ({})
    readonly property var wmo: ({
        0: "Clear", 1: "Mostly clear", 2: "Partly cloudy", 3: "Cloudy", 45: "Fog", 48: "Fog",
        51: "Light drizzle", 53: "Drizzle", 55: "Heavy drizzle", 56: "Freezing drizzle", 57: "Freezing drizzle",
        61: "Light rain", 63: "Rain", 65: "Heavy rain", 66: "Freezing rain", 67: "Freezing rain",
        71: "Light snow", 73: "Snow", 75: "Heavy snow", 77: "Snow grains",
        80: "Showers", 81: "Showers", 82: "Heavy showers", 85: "Snow showers", 86: "Snow showers",
        95: "Thunderstorm", 96: "Thunderstorm", 99: "Thunderstorm"
    })
    function wmoDesc(c) { return wmo[c] || "" }
    function wmoIcon(c, night) {
        if (c <= 1) return night ? "" : ""
        if (c === 2) return night ? "" : ""
        if (c === 3) return ""
        if (c === 45 || c === 48) return ""
        if (c >= 95) return ""
        if ((c >= 71 && c <= 77) || c === 85 || c === 86) return ""
        if ((c >= 51 && c <= 57) || (c >= 80 && c <= 82)) return ""
        return ""
    }
    Process {
        id: weekFetch
        command: ["python3", "-I", "-c", `
import json,re,sys,urllib.request,urllib.parse
place=sys.argv[1].strip()
lat,lon="37.8812","41.1351"
m=re.match(r"^\\s*(-?[0-9.]+)\\s*,\\s*(-?[0-9.]+)\\s*$",place)
if m: lat,lon=m.groups()
elif place:
    g=json.load(urllib.request.urlopen("https://geocoding-api.open-meteo.com/v1/search?count=1&name="+urllib.parse.quote(place),timeout=10))
    if g.get("results"): lat,lon=str(g["results"][0]["latitude"]),str(g["results"][0]["longitude"])
u=("https://api.open-meteo.com/v1/forecast?latitude="+lat+"&longitude="+lon+"&timezone=auto&past_days=6&forecast_days=8"
   "&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,wind_speed_10m_max,uv_index_max,sunrise,sunset"
   "&hourly=temperature_2m,weather_code,precipitation_probability")
j=json.load(urllib.request.urlopen(u,timeout=15)); d=j["daily"]; h=j["hourly"]; out={}
for i,day in enumerate(d["time"]):
    out[day]={"code":d["weather_code"][i] or 0,"max":round(d["temperature_2m_max"][i] or 0),"min":round(d["temperature_2m_min"][i] or 0),
              "rain":d["precipitation_probability_max"][i],"wind":round(d["wind_speed_10m_max"][i] or 0),"uv":round(d["uv_index_max"][i] or 0),
              "sunrise":(d["sunrise"][i] or "T")[-5:],"sunset":(d["sunset"][i] or "T")[-5:],"hours":[]}
for i,t in enumerate(h["time"]):
    day=t[:10]
    if day in out: out[day]["hours"].append({"h":int(t[11:13]),"temp":round(h["temperature_2m"][i] or 0),"code":h["weather_code"][i] or 0,"rain":h["precipitation_probability"][i] or 0})
print(json.dumps(out))`, Settings.cur("weather_place") || ""]
        stdout: StdioCollector { onStreamFinished: { try { const w = JSON.parse(this.text); if (Object.keys(w).length) week = w } catch (e) {} } }
    }
    Timer { interval: 30 * 60 * 1000; running: true; repeat: true; triggeredOnStart: true; onTriggered: weekFetch.running = true }
}
