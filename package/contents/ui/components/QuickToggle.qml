/*
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami

// GNOME-style pill toggle: icon + title + subtitle, with an optional arrow
// section on the right that opens a menu or sub-view.
Item {
    id: toggle

    property string iconName
    property string title
    property string subtitle
    property bool checked: false
    // False for plain action buttons that share the pill look (e.g. Screenshot).
    property bool checkable: true
    property bool busy: false
    // The backing service is down: greyed out, not clickable, no stale state.
    property bool unavailable: false
    readonly property bool effectiveChecked: checked && !unavailable

    property bool hasMenu: false
    property bool menuOpen: false
    property string menuLabel

    readonly property alias mainButton: mainButton
    readonly property alias menuButton: menuButton

    signal toggled()
    signal menuRequested()
    // Arrow keys move between the toggles of the grid this toggle sits in:
    // left/right step through them, up/down jump a row. Past the edges, focus
    // continues to whatever comes before or after the grid.
    function navigate(dx, dy) {
        const grid = parent;
        const toggles = grid.children.filter(child => child.mainButton !== undefined && child.visible);
        const index = toggles.indexOf(toggle);
        const target = toggles[index + dx + dy * (grid.columns ?? 1)];
        if (target) {
            (dx < 0 && target.hasMenu ? target.menuButton : target.mainButton).forceActiveFocus(Qt.TabFocusReason);
        } else if (dy < 0 || (dx < 0 && index === 0)) {
            toggles[0].mainButton.nextItemInFocusChain(false).forceActiveFocus(Qt.BacktabFocusReason);
        } else {
            const last = toggles[toggles.length - 1];
            (last.hasMenu ? last.menuButton : last.mainButton).nextItemInFocusChain(true).forceActiveFocus(Qt.TabFocusReason);
        }
    }

    implicitHeight: Math.max(Kirigami.Units.gridUnit * 3, content.implicitHeight + Kirigami.Units.smallSpacing * 2)
    implicitWidth: Kirigami.Units.gridUnit * 9

    readonly property color activeColor: Kirigami.Theme.highlightColor
    readonly property color inactiveColor: Kirigami.ColorUtils.linearInterpolation(Kirigami.Theme.backgroundColor, Kirigami.Theme.textColor, 0.12)
    enabled: !unavailable
    opacity: unavailable ? 0.6 : 1

    readonly property color foreground: effectiveChecked ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor

    Rectangle {
        id: pill
        anchors.fill: parent
        radius: height / 2
        color: toggle.effectiveChecked ? toggle.activeColor : toggle.inactiveColor

        Behavior on color {
            ColorAnimation {
                duration: Kirigami.Units.shortDuration
            }
        }
    }

    component PillButton: T.AbstractButton {
        id: button

        property int leftRadius: 0
        property int rightRadius: 0
        // Inline components cannot see the outer ids, so colors are passed in.
        property color foreground
        property bool onAccent: false

        hoverEnabled: true
        focusPolicy: Qt.StrongFocus

        background: Rectangle {
            topLeftRadius: button.leftRadius
            bottomLeftRadius: button.leftRadius
            topRightRadius: button.rightRadius
            bottomRightRadius: button.rightRadius
            color: button.foreground
            opacity: button.pressed ? 0.18 : (button.hovered ? 0.1 : 0)

            Rectangle {
                anchors.fill: parent
                topLeftRadius: parent.topLeftRadius
                bottomLeftRadius: parent.bottomLeftRadius
                topRightRadius: parent.topRightRadius
                bottomRightRadius: parent.bottomRightRadius
                visible: button.visualFocus
                color: "transparent"
                border.width: 2
                border.color: button.onAccent ? button.foreground : Kirigami.Theme.focusColor
            }
        }

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                button.clicked();
                event.accepted = true;
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        PillButton {
            id: mainButton
            foreground: toggle.foreground
            onAccent: toggle.effectiveChecked
            Layout.fillWidth: true
            Layout.fillHeight: true
            leftRadius: toggle.height / 2
            rightRadius: toggle.hasMenu ? 0 : toggle.height / 2

            leftPadding: Kirigami.Units.largeSpacing
            rightPadding: toggle.hasMenu ? Kirigami.Units.smallSpacing : Kirigami.Units.largeSpacing

            Accessible.role: toggle.checkable ? Accessible.CheckBox : Accessible.Button
            Accessible.checkable: toggle.checkable
            Accessible.checked: toggle.effectiveChecked
            Accessible.name: toggle.title
            Accessible.description: toggle.unavailable ? i18n("Unavailable") : toggle.subtitle
            Accessible.onToggleAction: toggle.toggled()
            Accessible.onPressAction: toggle.toggled()

            onClicked: toggle.toggled()

            Keys.onLeftPressed: toggle.navigate(-1, 0)
            Keys.onRightPressed: toggle.hasMenu ? menuButton.forceActiveFocus(Qt.TabFocusReason) : toggle.navigate(1, 0)
            Keys.onUpPressed: toggle.navigate(0, -1)
            Keys.onDownPressed: toggle.navigate(0, 1)

            contentItem: RowLayout {
                id: content
                spacing: Kirigami.Units.smallSpacing

                Item {
                    Layout.preferredWidth: Kirigami.Units.iconSizes.smallMedium
                    Layout.preferredHeight: Kirigami.Units.iconSizes.smallMedium

                    Kirigami.Icon {
                        anchors.fill: parent
                        source: toggle.iconName
                        color: toggle.foreground
                        isMask: true
                        visible: !toggle.busy
                    }
                    PlasmaComponents3.BusyIndicator {
                        anchors.fill: parent
                        visible: toggle.busy
                        running: visible
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    PlasmaComponents3.Label {
                        Layout.fillWidth: true
                        text: toggle.title
                        color: toggle.foreground
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                        textFormat: Text.PlainText
                    }
                    PlasmaComponents3.Label {
                        Layout.fillWidth: true
                        visible: text.length > 0
                        text: toggle.unavailable ? i18n("Unavailable") : toggle.subtitle
                        color: toggle.foreground
                        opacity: 0.8
                        font: Kirigami.Theme.smallFont
                        elide: Text.ElideRight
                        textFormat: Text.PlainText
                    }
                }
            }
        }

        PillButton {
            id: menuButton
            foreground: toggle.foreground
            onAccent: toggle.effectiveChecked
            visible: toggle.hasMenu
            Layout.fillHeight: true
            Layout.preferredWidth: toggle.height
            leftRadius: 0
            rightRadius: toggle.height / 2

            Accessible.role: Accessible.Button
            Accessible.name: toggle.menuLabel

            onClicked: toggle.menuRequested()

            Keys.onLeftPressed: mainButton.forceActiveFocus(Qt.TabFocusReason)
            Keys.onRightPressed: toggle.navigate(1, 0)
            Keys.onUpPressed: toggle.navigate(0, -1)
            Keys.onDownPressed: toggle.navigate(0, 1)

            contentItem: Item {
                Kirigami.Icon {
                    anchors.centerIn: parent
                    width: Kirigami.Units.iconSizes.small
                    height: width
                    source: toggle.menuOpen ? "go-up-symbolic" : "go-next-symbolic"
                    color: toggle.foreground
                    isMask: true
                }
            }

            // Thin divider between the toggle and its arrow, as in GNOME.
            Rectangle {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: 1
                height: parent.height * 0.5
                color: toggle.foreground
                opacity: 0.25
            }
        }
    }
}
