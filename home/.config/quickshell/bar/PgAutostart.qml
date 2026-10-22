// Settings → Autostart: apps that open when you log in. Made by Claude.
import QtQuick
import QtQuick.Controls.Basic
import Quickshell
import Quickshell.Widgets

Column {
    id: pg
    spacing: 14
    property string q: ""
    readonly property var chosen: Settings.get("autostart") || []
    readonly property var apps: DesktopEntries.applications.values.filter(a => !a.noDisplay)
    readonly property var found: q.length < 2 ? [] : apps.filter(a => a.name.toLowerCase().indexOf(q.toLowerCase()) >= 0 && chosen.indexOf(a.id + ".desktop") < 0 && chosen.indexOf(a.id) < 0).slice(0, 8)
    function entry(id) { const k = id.replace(/\.desktop$/, ""); return apps.find(a => a.id === k) || null }
    function add(a) { Settings.set("autostart", chosen.concat([a.id + ".desktop"])); q = ""; field.text = "" }
    function remove(id) { Settings.set("autostart", chosen.filter(x => x !== id)) }

    SetSection {
        width: parent.width; title: "Your apps"; icon: "\u{f0412}"
        Label { visible: pg.chosen.length === 0; text: "Nothing yet – add apps below and they'll open each time you log in."; color: Theme.muted; font.pixelSize: 11 }
        Repeater {
            model: pg.chosen
            Rectangle {
                id: ar
                required property string modelData
                readonly property var e: pg.entry(modelData)
                width: parent.width; height: 46; radius: 2; color: "#33111111"
                Row {
                    x: 12; anchors.verticalCenter: parent.verticalCenter; spacing: 12
                    IconImage { implicitSize: 26; source: Quickshell.iconPath(ar.e ? ar.e.icon : "application-x-executable", true); anchors.verticalCenter: parent.verticalCenter }
                    Label { text: ar.e ? ar.e.name : ar.modelData; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
                }
                SetButton { anchors.right: parent.right; anchors.rightMargin: 8; anchors.verticalCenter: parent.verticalCenter; icon: "\u{f0156}"; text: "Remove"; accent: Theme.red; onClicked: pg.remove(ar.modelData) }
            }
        }
        TextField {
            id: field
            width: parent.width; height: 40
            placeholderText: "Add an app – type its name…"; placeholderTextColor: Theme.muted
            onTextEdited: pg.q = text
            color: Theme.fg; font.family: Theme.font; font.pixelSize: 13; leftPadding: 12
            background: Rectangle { radius: 2; color: Theme.bgAlt; border.width: field.activeFocus ? 2 : 1; border.color: field.activeFocus ? Theme.blue : Theme.line }
            Keys.onReturnPressed: if (pg.found.length) pg.add(pg.found[0])
        }
        Repeater {
            model: pg.found
            Rectangle {
                id: fr
                required property var modelData
                width: parent.width; height: 40; radius: 2; color: fm.containsMouse ? Theme.bgHover : "transparent"
                Row {
                    x: 12; anchors.verticalCenter: parent.verticalCenter; spacing: 12
                    IconImage { implicitSize: 22; source: Quickshell.iconPath(fr.modelData.icon, true); anchors.verticalCenter: parent.verticalCenter }
                    Label { text: fr.modelData.name; font.pixelSize: 12; anchors.verticalCenter: parent.verticalCenter }
                    Label { text: "\u{f0415} add"; color: Theme.blue; font.pixelSize: 11; anchors.verticalCenter: parent.verticalCenter }
                }
                MouseArea { id: fm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: pg.add(fr.modelData) }
            }
        }
    }
    SetSection {
        width: parent.width; title: "Always running (part of the desktop)"; icon: "\u{f0493}"
        Repeater {
            model: [["\u{f0e9e}", "Top bar, control center, notifications"], ["\u{f02e9}", "Wallpaper"], ["\u{f033e}", "Auto-lock / screens off"],
                    ["\u{f014c}", "Clipboard history"], ["\u{f0483}", "Password prompts"], ["\u{f0200}", "Network tray icon"], ["\u{f04d9}", "Desktop doctor (restarts these if they stop)"]]
            Row {
                required property var modelData
                spacing: 12
                Label { width: 18; text: modelData[0]; color: Theme.muted }
                Label { text: modelData[1]; color: Theme.fgDim; font.pixelSize: 12 }
            }
        }
    }
}
