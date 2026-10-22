//@ pragma UseQApplication
//@ pragma IconTheme Tela-mono
// Yu's bar (Quickshell). Only on the main screen (DP-1). Made by Claude.
import Quickshell

ShellRoot {
    Variants {
        model: Quickshell.screens.filter(s => s.name === "DP-1")
        Bar {}
    }
    Variants {
        model: Quickshell.screens.filter(s => s.name === "DP-1")
        Osd { required property var modelData; screen: modelData }
    }
    Variants {
        model: Quickshell.screens.filter(s => s.name === "DP-1")
        NotifPopups { required property var modelData; screen: modelData }
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
        DesktopWidget { required property var modelData; screen: modelData }
    }
    Variants {
        model: Quickshell.screens.filter(s => s.name === "DP-1")
        LauncherShield { required property var modelData; screen: modelData }
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
