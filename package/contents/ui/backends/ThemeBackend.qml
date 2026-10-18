/*
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import org.kde.plasma.private.brightnesscontrolplugin

// Private API: DarkModeControl from org.kde.plasma.private.brightnesscontrolplugin (powerdevil).
// It switches between the default light and dark Global Themes.
Item {
    id: root
    visible: false

    readonly property bool darkMode: DarkModeControl.darkMode
    readonly property string currentTheme: DarkModeControl.currentTheme

    function setDarkMode(enable) {
        DarkModeControl.darkMode = enable;
    }
}
