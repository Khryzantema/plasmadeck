/*
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Controls as QQC2
import org.kde.kcmutils as KCMUtils
import org.kde.kirigami as Kirigami

// Look of the popup's toggle buttons.
KCMUtils.SimpleKCM {
    property bool cfg_pillButtons
    property bool cfg_pillButtonsDefault

    Kirigami.FormLayout {
        QQC2.RadioButton {
            Kirigami.FormData.label: i18n("Button style:")
            text: i18n("Plasma (rounded squares)")
            checked: !cfg_pillButtons
            onToggled: cfg_pillButtons = false
        }

        QQC2.RadioButton {
            text: i18n("Pill (GNOME style)")
            checked: cfg_pillButtons
            onToggled: cfg_pillButtons = true
        }
    }
}
