/*
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.networkmanagement as PlasmaNM

import "native"

// Network sub-page: a copy of Plasma's own Networks applet popup (toolbar with the Wi-Fi, mobile
// data, airplane mode and hotspot switches and a search field, then the connection list with
// expandable items, speed/details tabs and inline password entry). The files in "native/" come from
// plasma-nm's applet; the ids below (handler, mainWindow, ...) are the ones those files expect.
FocusScope {
    id: page

    // The network backend; its connection model is shared so the page opens without building one.
    property Item network: null

    signal back()

    // Default size of Plasma's Networks popup (20 grid units tall), read by FullRepresentation.
    readonly property real pagePreferredHeight: Kirigami.Units.gridUnit * 20

    // Read by ConnectionItem to refresh the traffic statistics.
    readonly property PlasmaNM.NetworkModel connectionModel: network?.connectionModel ?? null

    // Stands in for the applet's root item (PlasmoidItem) in the native files.
    QtObject {
        id: mainWindow
        property bool expanded: page.visible
        readonly property string kcm: "kcm_networkmanagement"
        readonly property bool kcmAuthorized: true
    }

    PlasmaNM.Handler {
        id: handler
    }

    PlasmaNM.NetworkStatus {
        id: networkStatus
    }

    PlasmaNM.AvailableDevices {
        id: availableDevices
    }

    PlasmaNM.AppletProxyModel {
        id: appletProxyModel
        sourceModel: page.connectionModel
    }

    // The first scan waits for the slide-in animation to end: it rewrites the model while the
    // page is still moving, which makes the opening stutter.
    Timer {
        running: page.visible
        interval: Kirigami.Units.longDuration + 50
        onTriggered: handler.requestScan()
    }

    Timer {
        interval: 10200
        repeat: true
        running: page.visible && !PlasmaNM.Configuration.airplaneModeEnabled && !(page.connectionModel?.delayModelUpdates ?? false)
        onTriggered: handler.requestScan()
    }

    Connections {
        target: handler
        function onWifiCodeReceived(data, ssid, password) {
            if (data.length === 0) {
                console.error("Cannot create QR code component: Unsupported connection");
                return;
            }
            stack.push(qrCodePage, { content: data, ssid: ssid, password: password });
        }
    }

    Component {
        id: qrCodePage
        ShareNetworkQrCodePage {}
    }

    Keys.onEscapePressed: {
        if (stack.depth > 1) {
            stack.pop();
        } else {
            page.back();
        }
    }
    Keys.onPressed: event => {
        if (event.modifiers & Qt.ControlModifier && event.key === Qt.Key_F) {
            toolbar.searchTextField.forceActiveFocus();
            toolbar.searchTextField.selectAll();
            event.accepted = true;
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Kirigami.Units.smallSpacing

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            PlasmaComponents3.ToolButton {
                id: backButton
                focus: true
                icon.name: page.LayoutMirroring.enabled ? "go-next-symbolic" : "go-previous-symbolic"
                text: i18n("Back")
                display: PlasmaComponents3.AbstractButton.IconOnly
                Accessible.name: text
                onClicked: stack.depth > 1 ? stack.pop() : page.back()
                PlasmaComponents3.ToolTip.text: text
                PlasmaComponents3.ToolTip.visible: hovered
                PlasmaComponents3.ToolTip.delay: Kirigami.Units.toolTipDelay
            }

            Toolbar {
                id: toolbar
                Layout.fillWidth: true
                hasConnections: connectionListPage.count > 0
                visible: stack.depth === 1
            }

            Item {
                Layout.fillWidth: true
                visible: stack.depth > 1
            }
        }

        QQC2.StackView {
            id: stack
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            initialItem: ConnectionListPage {
                id: connectionListPage
                model: appletProxyModel
                nmStatus: networkStatus
            }
        }
    }
}
