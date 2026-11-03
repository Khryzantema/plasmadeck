/*
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCMUtils
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.private.batterymonitor
import org.kde.plasma.private.battery

import "native"

// Power sub-page: a copy of Plasma's own Power & Battery applet popup (power profile, one entry
// per battery and the "manually block sleep and screen locking" switch). The files in "native/"
// come from the battery applet; the controllers below are the ones its main file creates.
FocusScope {
    id: page

    signal back()

    // Like Plasma's Power & Battery popup: as tall as its content, between 10 and 40 grid units.
    // Read by FullRepresentation.
    readonly property real pagePreferredHeight: Math.max(Kirigami.Units.gridUnit * 10,
        Math.min(Kirigami.Units.gridUnit * 40, headerRow.implicitHeight + powerPopup.implicitHeight + column.spacing))

    Keys.onEscapePressed: back()

    PowerProfilesControl {
        id: powerProfilesControl
    }

    BatteryControlModel {
        id: batteryControl

        readonly property int remainingTime: smoothedRemainingMsec
    }

    InhibitionControl {
        id: inhibitionControl
    }

    ColumnLayout {
        id: column
        anchors.fill: parent
        spacing: Kirigami.Units.smallSpacing

        RowLayout {
            id: headerRow
            Layout.fillWidth: true
            spacing: Kirigami.Units.smallSpacing

            PlasmaComponents3.ToolButton {
                id: backButton
                focus: true
                icon.name: page.LayoutMirroring.enabled ? "go-next-symbolic" : "go-previous-symbolic"
                text: i18n("Back")
                display: PlasmaComponents3.AbstractButton.IconOnly
                Accessible.name: text
                onClicked: page.back()
                PlasmaComponents3.ToolTip.text: text
                PlasmaComponents3.ToolTip.visible: hovered
                PlasmaComponents3.ToolTip.delay: Kirigami.Units.toolTipDelay
            }

            Kirigami.Heading {
                Layout.fillWidth: true
                level: 3
                text: batteryControl.hasBatteries ? i18nd("plasma_applet_org.kde.plasma.battery", "Power & Battery") : i18nd("plasma_applet_org.kde.plasma.battery", "Power Management")
                elide: Text.ElideRight
            }

            PlasmaComponents3.ToolButton {
                icon.name: "configure"
                text: i18n("Configure Power Management…")
                display: PlasmaComponents3.AbstractButton.IconOnly
                onClicked: KCMUtils.KCMLauncher.openSystemSettings("kcm_powerdevilprofilesconfig")
                PlasmaComponents3.ToolTip.text: text
                PlasmaComponents3.ToolTip.visible: hovered
                PlasmaComponents3.ToolTip.delay: Kirigami.Units.toolTipDelay
            }
        }

        PowerPopup {
            id: powerPopup
            Layout.fillWidth: true
            Layout.fillHeight: true

            model: batteryControl

            isManuallyInhibited: inhibitionControl.isManuallyInhibited
            isManuallyInhibitedError: inhibitionControl.isManuallyInhibitedError
            pluggedIn: batteryControl.pluggedIn
            chargeStopThreshold: batteryControl.chargeStopThreshold
            remainingTime: batteryControl.remainingTime
            activeProfile: powerProfilesControl.activeProfile
            activeProfileError: powerProfilesControl.profileError
            requestedInhibitions: inhibitionControl.requestedInhibitions
            inhibitsLidAction: inhibitionControl.isLidPresent && !inhibitionControl.triggersLidAction
            profilesInstalled: powerProfilesControl.isPowerProfileDaemonInstalled
            profiles: powerProfilesControl.profiles
            inhibitionReason: powerProfilesControl.inhibitionReason
            degradationReason: powerProfilesControl.degradationReason
            profileHolds: powerProfilesControl.profileHolds
            isTlpInstalled: powerProfilesControl.isTlpInstalled

            onActivateProfileRequested: profile => {
                powerProfilesControl.isSilent = page.visible;
                if (profile !== powerProfilesControl.activeProfile) {
                    powerProfilesControl.setProfile(profile);
                }
            }

            onInhibitionChangeRequested: inhibit => {
                inhibitionControl.isSilent = page.visible;
                if (inhibit) {
                    inhibitionControl.inhibit(i18n("PlasmaDeck has enabled suppressing sleep and screen locking"));
                } else {
                    inhibitionControl.uninhibit();
                }
            }

            onInhibitionAllowedRequested: (name, reason, allowed) => inhibitionControl.setInhibitionAllowed(name, reason, allowed)
        }
    }
}
