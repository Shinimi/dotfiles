// Settings: label + text box bound to a setting (draft). Made by Claude.
import QtQuick
import QtQuick.Controls.Basic

Column {
    id: r
    property string label; property string desc: ""; property string key; property string placeholder: ""
    width: parent ? parent.width : 300; spacing: 6
    Label { text: r.label; color: Theme.fgDim; font.pixelSize: 12 }
    TextField {
        id: f
        width: parent.width; height: 38
        text: Settings.get(r.key); onTextEdited: Settings.set(r.key, text)
        Connections { target: Settings; function onDraftChanged() { if (!f.activeFocus) f.text = Settings.get(r.key) } }
        placeholderText: r.placeholder; placeholderTextColor: Theme.muted
        color: Theme.fg; font.family: Theme.font; font.pixelSize: 13; leftPadding: 12
        background: Rectangle { radius: 10; color: Theme.bgAlt; border.width: f.activeFocus ? 2 : 1; border.color: f.activeFocus ? Theme.blue : Theme.line }
    }
    Label { visible: r.desc !== ""; width: parent.width; wrapMode: Text.WordWrap; text: r.desc; color: Theme.muted; font.pixelSize: 10 }
}
