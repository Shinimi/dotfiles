//@ pragma UseQApplication
//@ pragma IconTheme Tela-mono
// Yu's shell (Quickshell): dynamic island + panels. Only on the main screen (DP-1). Made by Claude.
import Quickshell

ShellRoot {
    WallShuffle {}
    Screensaver {}
    Variants {
        model: Quickshell.screens.filter(s => s.name === "DP-1")
        Ink { required property var modelData; screen: modelData }
    }
    Variants {
        model: Quickshell.screens.filter(s => s.name === "DP-1")
        HotCorner {}
    }
    Variants {
        model: Quickshell.screens.filter(s => s.name === "DP-1")
        Island {}
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
