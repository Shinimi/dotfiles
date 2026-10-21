// Wallpaper picker (SUPER + Y). Made by Claude.
import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
    id: root
    required property var screen
    property bool visible: false
    property string target: "DP-1"
    property var active: ({})
    readonly property string dir: Quickshell.env("HOME") + "/Pictures/wallpaper"

    function toggle() { visible = !visible }
    onVisibleChanged: if (visible) { listActive.running = true; PopupState.current = root }
    Connections { target: PopupState; function onCurrentChanged() { if (PopupState.current !== root) root.visible = false } }

    IpcHandler { target: "wallpaper"; function toggle(): void { root.toggle() } }

    Process {
        id: listActive
        command: ["hyprctl", "hyprpaper", "listactive"]
        stdout: StdioCollector {
            onStreamFinished: {
                const a = {}
                for (const l of this.text.split("\n")) { const i = l.indexOf(": "); if (i > 0) a[l.slice(0, i)] = l.slice(i + 2).trim() }
                root.active = a
            }
        }
    }
    function apply(path) {
        Quickshell.execDetached([Qt.resolvedUrl("setwall.sh").toString().replace("file://", ""), target, path])
        const a = Object.assign({}, active)
        if (target === "both") { a["DP-1"] = path; a["DP-2"] = path } else a[target] = path
        active = a
    }

    PanelWindow {   // click outside to close
        visible: root.visible; screen: root.screen
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "qsbar-dismiss"
        color: "#66000000"
        MouseArea { anchors.fill: parent; onClicked: root.visible = false }
    }

    PanelWindow {
        visible: root.visible; screen: root.screen
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "qsbar-wallpapers"
        WlrLayershell.keyboardFocus: root.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        color: "transparent"
        implicitWidth: 1000; implicitHeight: 640

        Rectangle {
            anchors.fill: parent; radius: 16; color: Theme.bg; border.width: 1; border.color: Theme.line
            focus: true
            Keys.onEscapePressed: root.visible = false

            ColumnLayout {
                anchors.fill: parent; anchors.margins: 18; spacing: 14
                RowLayout {
                    Layout.fillWidth: true; spacing: 8
                    Label { text: "  Wallpapers"; font.pixelSize: 16; font.weight: Font.Bold }
                    Label { text: folder.count + " images"; color: Theme.muted; font.pixelSize: 11; Layout.fillWidth: true }
                    Repeater {
                        model: [["DP-1", "Main screen"], ["DP-2", "Side screen"], ["both", "Both"]]
                        Rectangle {
                            required property var modelData
                            readonly property bool on: root.target === modelData[0]
                            width: tl.implicitWidth + 22; height: 28; radius: 8
                            color: on ? Theme.blue : (tMouse.containsMouse ? Theme.bgHover : Theme.bgAlt)
                            Label { id: tl; anchors.centerIn: parent; text: modelData[1]; color: on ? Theme.bg : Theme.fgDim; font.pixelSize: 11 }
                            MouseArea { id: tMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.target = modelData[0] }
                        }
                    }
                }
                GridView {
                    id: grid
                    Layout.fillWidth: true; Layout.fillHeight: true
                    clip: true
                    cellWidth: Math.floor(width / 5); cellHeight: Math.round(cellWidth * 9 / 16) + 8
                    model: FolderListModel {
                        id: folder
                        folder: "file://" + root.dir
                        nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp"]
                        showDirs: false
                        sortField: FolderListModel.Name
                    }
                    delegate: Item {
                        required property string filePath
                        width: grid.cellWidth; height: grid.cellHeight
                        readonly property bool isMain: root.active["DP-1"] === filePath
                        readonly property bool isSide: root.active["DP-2"] === filePath
                        Rectangle {
                            anchors.fill: parent; anchors.margins: 4; radius: 10
                            color: Theme.bgAlt
                            border.width: (isMain || isSide) ? 3 : (wMouse.containsMouse ? 2 : 0)
                            border.color: (isMain || isSide) ? Theme.blue : Theme.line
                            Image {
                                anchors.fill: parent; anchors.margins: parent.border.width
                                source: "file://" + filePath
                                sourceSize.width: 360
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true; cache: true
                            }
                            Row {
                                visible: isMain || isSide
                                anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.margins: 8; spacing: 4
                                Rectangle { visible: isMain; width: 40; height: 18; radius: 5; color: Theme.blue; Label { anchors.centerIn: parent; text: "main"; color: Theme.bg; font.pixelSize: 10 } }
                                Rectangle { visible: isSide; width: 36; height: 18; radius: 5; color: Theme.purple; Label { anchors.centerIn: parent; text: "side"; color: Theme.bg; font.pixelSize: 10 } }
                            }
                            MouseArea { id: wMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.apply(filePath) }
                        }
                    }
                }
            }
        }
    }
}
