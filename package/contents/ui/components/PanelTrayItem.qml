/*
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore

// One StatusNotifierItem shown directly in the panel.
PlasmaCore.ToolTipArea {
    id: item

    required property var model
    required property Item tray
    required property TrayMenu trayMenu
    required property int iconSize

    readonly property string source: model.DataEngineSource
    readonly property string itemId: model.Id
    readonly property string title: model.Title || model.ToolTipTitle || model.Id
    readonly property bool needsAttention: model.Status === PlasmaCore.Types.NeedsAttentionStatus

    implicitWidth: iconSize + Kirigami.Units.smallSpacing * 2
    implicitHeight: implicitWidth
    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight

    mainText: title
    subText: model.ToolTipSubTitle && model.ToolTipSubTitle !== title ? model.ToolTipSubTitle : ""
    textFormat: Text.AutoText

    activeFocusOnTab: true
    Accessible.role: Accessible.Button
    Accessible.name: title
    Accessible.description: needsAttention ? i18n("Needs attention") : subText
    Accessible.onPressAction: activate()

    function globalCenter() {
        return mapToGlobal(width / 2, height / 2);
    }

    function openMenu() {
        trayMenu.open(source, itemId, item, globalCenter());
    }

    function activate() {
        if (model.ItemIsMenu) {
            openMenu();
            return;
        }
        const pos = globalCenter();
        // Like Plasma's tray: apps using libappindicator (e.g. Steam) reject Activate; show their menu instead.
        tray.activate(source, pos.x, pos.y, () => openMenu());
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            activate();
            event.accepted = true;
        } else if (event.key === Qt.Key_Menu || (event.key === Qt.Key_F10 && (event.modifiers & Qt.ShiftModifier))) {
            openMenu();
            event.accepted = true;
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton

        onClicked: event => {
            if (event.button === Qt.LeftButton) {
                item.activate();
            } else if (event.button === Qt.RightButton) {
                item.openMenu();
            } else {
                const pos = item.globalCenter();
                item.tray.secondaryActivate(item.source, pos.x, pos.y);
            }
        }
        onWheel: wheel => {
            if (wheel.angleDelta.y !== 0) {
                item.tray.scroll(item.source, wheel.angleDelta.y, "vertical");
            }
            if (wheel.angleDelta.x !== 0) {
                item.tray.scroll(item.source, wheel.angleDelta.x, "horizontal");
            }
        }
    }

    Kirigami.Icon {
        id: icon
        anchors.centerIn: parent
        width: item.iconSize
        height: width
        active: mouse.containsMouse || item.activeFocus
        source: {
            if (item.needsAttention && (item.model.AttentionIcon || item.model.AttentionIconName)) {
                return item.model.AttentionIcon || item.model.AttentionIconName;
            }
            return item.model.Icon || item.model.IconName || "application-x-executable";
        }

        // Subtle pulse while the item needs attention; skipped when animations are disabled.
        SequentialAnimation on opacity {
            running: item.needsAttention && Kirigami.Units.longDuration > 0
            loops: Animation.Infinite
            alwaysRunToEnd: true
            NumberAnimation { to: 0.45; duration: Kirigami.Units.veryLongDuration * 2; easing.type: Easing.InOutQuad }
            NumberAnimation { to: 1; duration: Kirigami.Units.veryLongDuration * 2; easing.type: Easing.InOutQuad }
        }
    }

    // Attention badge.
    Rectangle {
        visible: item.needsAttention
        anchors.top: icon.top
        anchors.right: icon.right
        anchors.topMargin: -height / 4
        anchors.rightMargin: -width / 4
        width: Math.max(Kirigami.Units.smallSpacing * 2, item.iconSize / 3)
        height: width
        radius: width / 2
        color: Kirigami.Theme.negativeTextColor
        border.width: 1
        border.color: Kirigami.Theme.backgroundColor
    }

    // Keyboard focus ring.
    Rectangle {
        anchors.fill: parent
        visible: item.activeFocus
        color: "transparent"
        radius: Kirigami.Units.cornerRadius
        border.width: 1
        border.color: Kirigami.Theme.focusColor
    }
}
