/*
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import org.kde.plasma.configuration

// Pages of the widget settings dialog.
ConfigModel {
    ConfigCategory {
        name: i18n("System Tray")
        icon: "preferences-desktop-notification-symbolic"
        source: "ConfigTray.qml"
    }
}
