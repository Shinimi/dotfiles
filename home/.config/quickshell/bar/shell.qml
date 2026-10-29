//@ pragma UseQApplication
//@ pragma IconTheme Tela-mono
// Yu's shell (Quickshell): dynamic island + panels. Only on the main screen (DP-1). Made by Claude.
import Quickshell

ShellRoot {
    readonly property bool _screenTime: ScreenTime.enabled   // starts the screen time tracker with the shell
    readonly property bool _musicStats: MusicStats.enabled   // and the music one
    Intro {}
    Curtain {}
    AsciiWall {}
    WallShuffle {}
    Variants {
        model: Quickshell.screens.filter(s => s.name === "DP-1")
        Notes { required property var modelData; screen: modelData }
    }
    Variants {
        model: Quickshell.screens.filter(s => s.name === "DP-1")
        ShortcutSheet { required property var modelData; screen: modelData }
    }
    Variants {
        model: Quickshell.screens.filter(s => s.name === "DP-1")
        ControlPanel { required property var modelData; screen: modelData }
    }
    Variants {
        model: Quickshell.screens.filter(s => s.name === "DP-1")
        HomeScreen { required property var modelData; screen: modelData }
    }
    Screensaver {}
    DeskClock {}
    Osd {}
    AutoPause {}
    Variants {
        model: Quickshell.screens.filter(s => s.name === "DP-1")
        Ink { required property var modelData; screen: modelData }
    }
    Variants {
        model: Quickshell.screens.filter(s => s.name === "DP-1")
        HotCorner {}
    }
    Variants {   // the bar: main screen only
        model: Quickshell.screens.filter(s => s.name === "DP-1")
        Island {}
    }
    Variants {   // the side screen: just its workspaces
        model: Quickshell.screens.filter(s => s.name === "DP-2")
        SideBar {}
    }
    Variants {
        model: Quickshell.screens.filter(s => s.name === "DP-1")
        NotifPopups {}
    }
    Variants {
        model: Quickshell.screens.filter(s => s.name === "DP-1")
        WallpaperPicker { required property var modelData; screen: modelData }
    }
    Variants {
        model: Quickshell.screens.filter(s => s.name === "DP-1")
        AltTab { required property var modelData; screen: modelData }
    }
    Variants {
        model: Quickshell.screens.filter(s => s.name === "DP-1")
        EmojiPicker { required property var modelData; screen: modelData }
    }
    Variants {
        model: Quickshell.screens.filter(s => s.name === "DP-1")
        GameLibrary { required property var modelData; screen: modelData }
    }
    Variants {
        model: Quickshell.screens.filter(s => s.name === "DP-1")
        GameOverlay { required property var modelData; screen: modelData }
    }
    Variants {
        model: Quickshell.screens.filter(s => s.name === "DP-1")
        HyprSettings { required property var modelData; screen: modelData }
    }
    Variants {
        model: Quickshell.screens.filter(s => s.name === "DP-1")
        Clipboard { required property var modelData; screen: modelData }
    }
    Variants {
        model: Quickshell.screens.filter(s => s.name === "DP-1")
        DesktopWidget {}
    }
    Variants {
        model: Quickshell.screens.filter(s => s.name === "DP-1")
        Overview { required property var modelData; screen: modelData }
    }
    Variants {
        model: Quickshell.screens.filter(s => s.name === "DP-1")
        AppLauncher { required property var modelData; screen: modelData }
    }
}
