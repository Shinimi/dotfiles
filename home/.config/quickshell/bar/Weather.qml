// Weather from wttr.in (location auto-detected), refreshed every 20 min. Made by Claude.
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
    onWhereChanged: Qt.callLater(() => fetch.running = true)
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
}
