/*
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import org.kde.plasma.private.brightnesscontrolplugin

// Private API: org.kde.plasma.private.brightnesscontrolplugin (powerdevil).
// Covers internal backlights and DDC/CI external monitors.
Item {
    id: root
    visible: false

    readonly property bool available: control.isBrightnessAvailable
    readonly property var displays: control.displays

    // Level of the first display, for the panel icon.
    readonly property int percent: {
        const display = firstDisplay.count > 0 ? firstDisplay.objectAt(0) : null;
        return display && display.maxBrightness > 0 ? Math.round(display.brightness / display.maxBrightness * 100) : 0;
    }
    readonly property string panelIcon: available ? (percent < 50 ? "brightness-low-symbolic" : "brightness-high-symbolic") : ""

    function setBrightness(displayName, value) {
        control.setBrightness(displayName, Math.round(value));
    }

    // Same stepping as the native Brightness applet (shows the OSD).
    function stepUp(small) {
        control.adjustBrightnessStep(small ? ScreenBrightnessControl.IncreaseSmall : ScreenBrightnessControl.Increase);
    }

    function stepDown(small) {
        control.adjustBrightnessStep(small ? ScreenBrightnessControl.DecreaseSmall : ScreenBrightnessControl.Decrease);
    }

    ScreenBrightnessControl {
        id: control
    }

    Instantiator {
        id: firstDisplay
        model: control.displays
        delegate: QtObject {
            required property int brightness
            required property int maxBrightness
        }
    }
}
