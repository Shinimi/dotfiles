// Settings: label + text box bound to a setting (draft). Made by Claude.
import QtQuick
import QtQuick.Controls.Basic
import "."   // our own Label (Geist Mono) wins over the Qt Controls one

Column {
    id: r
    property string label; property string desc: ""; property string key; property string placeholder: ""
    width: parent ? parent.width : 300; spacing: 6
    Label { text: r.label; color: "#e0e0e0"; font.pixelSize: 12 }
    TextField {
        id: f
        width: parent.width; height: 38
        text: Settings.get(r.key); onTextEdited: Settings.set(r.key, text)
        Connections { target: Settings; function onDraftChanged() { if (!f.activeFocus) f.text = Settings.get(r.key) } }
        placeholderText: r.placeholder; placeholderTextColor: Theme.muted
        color: Theme.fg; font.family: Theme.font; font.pixelSize: 13; leftPadding: 12
        background: Rectangle { radius: 2; color: "#0cffffff"; border.width: 1; border.color: f.activeFocus ? "#99ffffff" : "#33ffffff"
                                Rectangle { visible: f.activeFocus; width: 2; height: parent.height; color: "#ffffff" } }
    }
    Label { visible: r.desc !== ""; width: parent.width; wrapMode: Text.WordWrap; text: r.desc; color: Theme.muted; font.pixelSize: 10 }
}
