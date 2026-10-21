// Tokyo Night: allow userChrome.css / userContent.css and use the dark theme. Made by Claude.
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
user_pref("layout.css.prefers-color-scheme.content-override", 0);
user_pref("ui.systemUsesDarkTheme", 1);
user_pref("browser.theme.content-theme", 0);
user_pref("browser.theme.toolbar-theme", 0);
user_pref("extensions.activeThemeID", "firefox-compact-dark@mozilla.org");
// Windows-style middle-click autoscroll. Made by Claude.
user_pref("general.autoScroll", true);
user_pref("middlemouse.paste", true);
