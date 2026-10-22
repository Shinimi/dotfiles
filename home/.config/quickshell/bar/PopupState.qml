// Only one panel open at a time. Made by Claude.
pragma Singleton
import QtQuick
import Quickshell
Singleton {
    property var current: null
    property bool focusMode: false      // focus mode: every screen's bar hides
}
