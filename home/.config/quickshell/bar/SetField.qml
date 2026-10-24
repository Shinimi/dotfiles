// Settings: label + text box bound to a setting (draft). Made by Claude.
import QtQuick
import QtQuick.Controls.Basic
import "."   // our own Label wins over the Qt Controls one

Item {
    id: r
    property string label; property string desc: ""; property string key; property string placeholder: ""
    width: parent ? parent.width : 300; implicitHeight: inner.implicitHeight
    SetRowLine { show: r.Positioner.index > 0 }
    Column {
        id: inner
        width: parent.width; spacing: 6
        Label { text: r.label; color: "#e6e6e6"; font.pixelSize: 12 }
        TextField {
            id: f
            width: parent.width; height: 36
            text: Settings.get(r.key); onTextEdited: Settings.set(r.key, text)
            Connections { target: Settings; function onDraftChanged() { if (!f.activeFocus) f.text = Settings.get(r.key) } }
            placeholderText: r.placeholder; placeholderTextColor: Theme.muted
            color: Theme.fg; font.family: Theme.font; font.pixelSize: 12; leftPadding: 12
            background: Rectangle { radius: 10; color: "#0e0e0e"; border.width: 1; border.color: f.activeFocus ? "#55ffffff" : "#262626" }
        }
        Label { visible: r.desc !== ""; width: parent.width; wrapMode: Text.WordWrap; text: r.desc.charAt(0).toUpperCase() + r.desc.slice(1); color: Theme.muted; font.pixelSize: 10 }
    }
}
