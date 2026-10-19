/*
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami

// GNOME-style slider row: [icon button] [slider] [optional expand arrow].
RowLayout {
    id: row

    property string iconName
    property string iconButtonLabel
    // When false the icon is purely decorative (e.g. brightness has nothing to toggle).
    property bool iconInteractive: true
    property string accessibleName

    property real from: 0
    property real to: 100
    property real stepSize: 1
    // Externally owned value; the slider follows it except while being dragged.
    property real value: 0
    property bool dimmed: false

    property bool expandable: false
    property bool expanded: false
    property string expandLabel

    readonly property int percent: to > from ? Math.round((slider.value - from) / (to - from) * 100) : 0

    signal iconClicked()
    signal moved(real value)
    signal released()
    signal expandToggled()

    spacing: Kirigami.Units.smallSpacing

    Kirigami.Icon {
        visible: !row.iconInteractive
        source: row.iconName
        // Match the footprint of the ToolButton used in interactive rows.
        Layout.preferredWidth: iconButton.implicitWidth
        Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium
    }

    PlasmaComponents3.ToolButton {
        id: iconButton
        visible: row.iconInteractive
        icon.name: row.iconName
        text: row.iconButtonLabel
        display: PlasmaComponents3.AbstractButton.IconOnly
        onClicked: row.iconClicked()

        Accessible.name: row.iconButtonLabel
        PlasmaComponents3.ToolTip.text: row.iconButtonLabel
        PlasmaComponents3.ToolTip.visible: hovered && row.iconButtonLabel.length > 0
        PlasmaComponents3.ToolTip.delay: Kirigami.Units.toolTipDelay
    }

    PlasmaComponents3.Slider {
        id: slider
        Layout.fillWidth: true
        from: row.from
        to: row.to
        stepSize: row.stepSize
        opacity: row.dimmed ? 0.5 : 1

        Accessible.name: row.accessibleName
        Accessible.description: i18nc("Slider value as a percentage", "%1%", row.percent)

        onMoved: row.moved(value)
        onPressedChanged: {
            if (!pressed) {
                row.released();
            }
        }
    }

    // The slider shows the real value, except while it is being dragged: the
    // system answers each change a moment later with the previous value, and
    // following those answers made the handle jump back and forth under the
    // pointer. When released it snaps to the real value again (the backend
    // may have clamped it).
    Binding {
        target: slider
        property: "value"
        value: row.value
        when: !slider.pressed
        restoreMode: Binding.RestoreNone
    }

    PlasmaComponents3.ToolButton {
        visible: row.expandable
        icon.name: row.expanded ? "go-up-symbolic" : "go-next-symbolic"
        text: row.expandLabel
        display: PlasmaComponents3.AbstractButton.IconOnly
        checkable: true
        checked: row.expanded
        onClicked: row.expandToggled()

        Accessible.name: row.expandLabel
        PlasmaComponents3.ToolTip.text: row.expandLabel
        PlasmaComponents3.ToolTip.visible: hovered
        PlasmaComponents3.ToolTip.delay: Kirigami.Units.toolTipDelay
    }
}
