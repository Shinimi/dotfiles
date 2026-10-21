// Hyprland settings panel (SUPER + comma). Changes apply live and are saved. Made by Claude.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
    id: root
    required property var screen
    property bool visible: false
    function toggle() { visible = !visible }
    onVisibleChanged: if (visible) PopupState.current = root
    Connections { target: PopupState; function onCurrentChanged() { if (PopupState.current !== root) root.visible = false } }
    IpcHandler {
        target: "settings"
        function toggle(): void { root.toggle() }
        function set(key: string, value: string): void {
            Settings.set(key, value === "true" ? true : value === "false" ? false : Number(value))
        }
    }

    PanelWindow {
        visible: root.visible; screen: root.screen
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "qsbar-dismiss"
        color: "#33000000"
        MouseArea { anchors.fill: parent; onClicked: root.visible = false }
    }

    PanelWindow {
        visible: root.visible; screen: root.screen
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "qsbar-panel"
        WlrLayershell.keyboardFocus: root.visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        color: "transparent"
        implicitWidth: 980; implicitHeight: body.implicitHeight + 48

        Rectangle {
            anchors.fill: parent; radius: 20; color: Theme.panel; border.width: 1; border.color: Theme.glassLine
            focus: true
            Keys.onEscapePressed: root.visible = false

            Column {
                id: body
                x: 24; y: 24; width: parent.width - 48; spacing: 16
                RowLayout {
                    width: parent.width
                    Label { text: "  Hyprland settings"; font.pixelSize: 17; font.weight: Font.Bold; Layout.fillWidth: true }
                    Label { text: "changes apply instantly"; color: Theme.muted; font.pixelSize: 11 }
                    Rectangle {
                        width: rl.implicitWidth + 22; height: 28; radius: 14
                        color: rMouse.containsMouse ? "#33c0caf5" : Theme.card
                        Label { id: rl; anchors.centerIn: parent; text: "  Reset"; color: Theme.fgDim; font.pixelSize: 11 }
                        MouseArea { id: rMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Settings.reset() }
                    }
                }
                Row {
                    id: cols
                    width: parent.width; spacing: 14
                    readonly property real colW: (width - 2 * spacing) / 3
                    SetSection {
                        width: cols.colW
                        title: "Look"; icon: ""
                        SetSlider { label: "Gaps between windows"; key: "gaps_in"; from: 0; to: 20; suffix: " px" }
                        SetSlider { label: "Gaps at screen edges"; key: "gaps_out"; from: 0; to: 40; suffix: " px" }
                        SetSlider { label: "Border size"; key: "border_size"; from: 0; to: 6; suffix: " px" }
                        SetSlider { label: "Corner rounding"; key: "rounding"; from: 0; to: 20; suffix: " px" }
                        SetToggle { label: "Shadows"; key: "shadows" }
                        SetToggle { label: "Animations"; key: "animations" }
                    }
                    SetSection {
                        width: cols.colW
                        title: "Glass"; icon: ""
                        SetSlider { label: "Focused window"; key: "opacity_active"; from: 50; to: 100; suffix: "%" }
                        SetSlider { label: "Unfocused windows"; key: "opacity_inactive"; from: 40; to: 100; suffix: "%" }
                        SetSlider { label: "Bar & panels glass"; key: "glass"; from: 0; to: 100; suffix: "%" }
                        SetToggle { label: "Blur"; desc: "frosted background behind glass"; key: "blur" }
                        SetSlider { label: "Blur strength"; key: "blur_size"; from: 1; to: 14 }
                        SetSlider { label: "Blur quality"; key: "blur_passes"; from: 1; to: 4 }
                    }
                    SetSection {
                        width: cols.colW
                        title: "Input & behavior"; icon: ""
                        SetSlider { label: "Mouse speed"; key: "sensitivity"; from: -1; to: 1; step: 0.05; decimals: 2 }
                        SetToggle { label: "Focus follows mouse"; key: "follow_mouse" }
                        SetToggle { label: "Middle-click scrolling"; desc: "hold middle button + move"; key: "middle_scroll" }
                        SetToggle { label: "Focus on activate"; desc: "apps can pull you to them"; key: "focus_on_activate" }
                        SetSlider { label: "Night light warmth"; key: "night_temp"; from: 2500; to: 6500; step: 100; suffix: " K" }
                    }
                }
            }
        }
    }
}
