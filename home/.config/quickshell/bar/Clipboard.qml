// Clipboard history (SUPER + V), like Windows 11. Text and images; Enter pastes. Made by Claude.
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
    id: root
    required property var screen
    property bool visible: false
    property var items: []
    property string query: ""
    property int sel: 0
    readonly property string helper: Qt.resolvedUrl("clip.sh").toString().replace("file://", "")
    readonly property var shown: {
        const q = query.trim().toLowerCase()
        return q ? items.filter(x => x.text.toLowerCase().indexOf(q) >= 0) : items
    }
    onShownChanged: sel = 0

    function toggle() { visible = !visible }
    onVisibleChanged: if (visible) { query = ""; sel = 0; PopupState.current = root; load.running = true }
    Connections { target: PopupState; function onCurrentChanged() { if (PopupState.current !== root) root.visible = false } }
    IpcHandler { target: "clipboard"; function toggle(): void { root.toggle() } }

    Process {
        id: load
        command: [root.helper, "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = []
                for (const l of this.text.split("\n")) {
                    const p = l.split("\t"); if (p.length < 4) continue
                    out.push({ id: p[0], img: p[1] === "1", path: p[2], text: p.slice(3).join("\t") })
                }
                root.items = out
            }
        }
    }
    function paste(it) {
        if (!it) return
        root.visible = false
        Quickshell.execDetached([helper, "paste", it.id])
    }
    function remove(it) {
        items = items.filter(x => x.id !== it.id)
        Quickshell.execDetached([helper, "delete", it.id])
    }

    PanelWindow {
        visible: root.visible; screen: root.screen
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "qsbar-dismiss"
        color: "#44000000"
        MouseArea { anchors.fill: parent; onClicked: root.visible = false }
    }

    PanelWindow {
        visible: root.visible; screen: root.screen
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "qsbar-clipboard"
        WlrLayershell.keyboardFocus: root.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        color: "transparent"
        implicitWidth: 520; implicitHeight: 600

        Rectangle {
            anchors.fill: parent; radius: 20; color: Theme.panel; border.width: 1; border.color: Theme.glassLine
            ColumnLayout {
                anchors.fill: parent; anchors.margins: 16; spacing: 12

                RowLayout {
                    Layout.fillWidth: true; spacing: 10
                    Label { text: "󰅌"; color: Theme.blue; font.pixelSize: 20 }
                    Label { text: "Clipboard"; color: Theme.fg; font.pixelSize: 16; font.bold: true; Layout.fillWidth: true }
                    Rectangle {
                        implicitWidth: clearTxt.implicitWidth + 22; implicitHeight: 28; radius: 9
                        color: clearMouse.containsMouse ? Qt.rgba(0.81, 0.42, 0.42, 0.18) : Theme.bgAlt
                        visible: root.items.length > 0
                        Label { id: clearTxt; anchors.centerIn: parent; text: "󰩺  Clear all"; color: clearMouse.containsMouse ? Theme.red : Theme.fgDim; font.pixelSize: 11 }
                        MouseArea {
                            id: clearMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: { root.items = []; Quickshell.execDetached([root.helper, "wipe"]) }
                        }
                    }
                }

                TextField {
                    id: search
                    Layout.fillWidth: true; Layout.preferredHeight: 42
                    focus: root.visible
                    onVisibleChanged: if (visible) forceActiveFocus()
                    text: root.query; onTextChanged: root.query = text
                    placeholderText: "Search clipboard…"; placeholderTextColor: Theme.muted
                    color: Theme.fg; font.family: Theme.font; font.pixelSize: 14
                    leftPadding: 40
                    background: Rectangle { radius: 12; color: Theme.bgAlt; border.width: search.activeFocus ? 2 : 1; border.color: search.activeFocus ? Theme.blue : Theme.line }
                    Label { x: 14; anchors.verticalCenter: parent.verticalCenter; text: "󰍉"; color: Theme.muted; font.pixelSize: 15 }
                    Keys.onEscapePressed: root.visible = false
                    Keys.onReturnPressed: root.paste(root.shown[root.sel])
                    Keys.onDownPressed: { root.sel = Math.min(root.sel + 1, root.shown.length - 1); list.positionViewAtIndex(root.sel, ListView.Contain) }
                    Keys.onUpPressed: { root.sel = Math.max(root.sel - 1, 0); list.positionViewAtIndex(root.sel, ListView.Contain) }
                    Keys.onDeletePressed: if (root.shown[root.sel]) root.remove(root.shown[root.sel])
                }

                ListView {
                    id: list
                    Layout.fillWidth: true; Layout.fillHeight: true
                    clip: true; spacing: 6
                    model: root.shown
                    boundsBehavior: Flickable.StopAtBounds
                    delegate: Rectangle {
                        id: row
                        required property var modelData
                        required property int index
                        readonly property bool current: index === root.sel
                        width: list.width
                        height: modelData.img ? 110 : Math.min(76, txt.implicitHeight + 24)
                        radius: 12
                        color: current ? Qt.rgba(0.88, 0.88, 0.88, 0.16) : (rowMouse.containsMouse ? Theme.bgHover : Theme.card)
                        border.width: current ? 1 : 0; border.color: Theme.blue
                        Behavior on color { ColorAnimation { duration: 120 } }

                        MouseArea {
                            id: rowMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onContainsMouseChanged: if (containsMouse) root.sel = row.index
                            onClicked: root.paste(row.modelData)
                        }
                        Text {
                            id: txt
                            visible: !row.modelData.img
                            anchors { left: parent.left; right: del.left; verticalCenter: parent.verticalCenter; leftMargin: 14; rightMargin: 8 }
                            text: row.modelData.text
                            color: Theme.fg; font.family: Theme.font; font.pixelSize: 12
                            wrapMode: Text.WrapAnywhere; maximumLineCount: 3; elide: Text.ElideRight
                        }
                        Rectangle {
                            visible: row.modelData.img
                            anchors { left: parent.left; top: parent.top; bottom: parent.bottom; margins: 8 }
                            width: 160; radius: 8; color: Theme.bgAlt; clip: true
                            Image {
                                anchors.fill: parent; anchors.margins: 2
                                source: row.modelData.img ? "file://" + row.modelData.path : ""
                                fillMode: Image.PreserveAspectFit; asynchronous: true; cache: false
                                sourceSize.width: 320
                            }
                        }
                        Label {
                            visible: row.modelData.img
                            anchors { left: parent.left; leftMargin: 184; verticalCenter: parent.verticalCenter }
                            text: "󰋩  Image\n" + row.modelData.text
                            color: Theme.fgDim; font.pixelSize: 11; lineHeight: 1.3
                        }
                        Rectangle {
                            id: del
                            anchors { right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
                            width: 28; height: 28; radius: 8
                            opacity: rowMouse.containsMouse || delMouse.containsMouse || row.current ? 1 : 0
                            color: delMouse.containsMouse ? Qt.rgba(0.81, 0.42, 0.42, 0.2) : "transparent"
                            Label { anchors.centerIn: parent; text: "󰆴"; color: delMouse.containsMouse ? Theme.red : Theme.muted; font.pixelSize: 14 }
                            MouseArea { id: delMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.remove(row.modelData) }
                        }
                    }
                    Label {
                        anchors.centerIn: parent; visible: root.shown.length === 0
                        text: root.items.length ? "Nothing matches" : "󰅌\n\nCopy something and it shows up here"
                        horizontalAlignment: Text.AlignHCenter; color: Theme.muted; font.pixelSize: 13
                    }
                }

                Label {
                    Layout.fillWidth: true
                    text: "↑↓ choose · Enter paste · Del remove · Esc close"
                    color: Theme.muted; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter
                }
            }
        }
    }
}
