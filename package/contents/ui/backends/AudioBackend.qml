/*
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import org.kde.plasma.private.volume

// Private API: org.kde.plasma.private.volume (plasma-pa).
Item {
    id: root
    visible: false

    // plasma-pa exposes this placeholder sink when no real output exists.
    readonly property string dummyOutputName: "auto_null"

    readonly property var sink: PreferredDevice.sink
    readonly property var source: PreferredDevice.source
    readonly property bool hasSink: isRealDevice(sink)
    readonly property bool hasSource: isRealDevice(source)

    readonly property int normalVolume: PulseAudio.NormalVolume
    // Shared with Plasma's own Audio Volume applet ("Raise maximum volume", up to 150%).
    readonly property bool raiseMaximumVolume: config.raiseMaximumVolume
    readonly property int volumePercent: hasSink ? percentOf(sink.volume) : 0
    readonly property bool muted: hasSink ? sink.muted : true
    readonly property string panelIcon: iconFor(volumePercent, muted, "audio-volume")

    readonly property int sourceVolumePercent: hasSource ? percentOf(source.volume) : 0
    readonly property bool sourceMuted: hasSource ? source.muted : true
    // There are no "warning"/"danger" microphone icons, so cap the level used for the icon.
    readonly property string sourceIcon: iconFor(Math.min(sourceVolumePercent, 100), sourceMuted, "microphone-sensitivity")

    readonly property PulseObjectFilterModel sinks: PulseObjectFilterModel {
        filterOutInactiveDevices: true
        filterVirtualDevices: true
        sourceModel: SinkModel {}
    }

    readonly property PulseObjectFilterModel sources: PulseObjectFilterModel {
        filterOutInactiveDevices: true
        filterVirtualDevices: true
        sourceModel: SourceModel {}
    }

    function isRealDevice(device) {
        return device !== null && device !== undefined && device.name !== dummyOutputName;
    }

    function percentOf(volume) {
        return Math.round(volume / PulseAudio.NormalVolume * 100);
    }

    function iconFor(percent, isMuted, prefix) {
        return AudioIcon.forVolume(percent, isMuted, prefix);
    }

    function deviceName(device) {
        if (!device) {
            return "";
        }
        return device.description || device.name || i18n("Unknown device");
    }

    function setVolume(device, value) {
        if (!isRealDevice(device)) {
            return;
        }
        device.volume = Math.round(value);
        device.muted = value === 0;
    }

    // Upper slider bound for a device: 150% when raising is allowed or the device is already above 100%.
    function maximumFor(device) {
        return raiseMaximumVolume || (device && device.volume > PulseAudio.NormalVolume * 1.01) ? PulseAudio.MaximalVolume : PulseAudio.NormalVolume;
    }

    function setRaiseMaximumVolume(enable) {
        config.raiseMaximumVolume = enable;
        config.save();
        // Like the native applet: lowering the limit brings louder devices back to 100%.
        if (!enable) {
            [sink, source].forEach(device => {
                if (isRealDevice(device) && device.volume > PulseAudio.NormalVolume) {
                    device.volume = PulseAudio.NormalVolume;
                }
            });
        }
    }

    function toggleMute(device) {
        if (isRealDevice(device)) {
            device.muted = !device.muted;
        }
    }

    function setDefault(device) {
        if (isRealDevice(device)) {
            device.default = true;
        }
    }

    // Step changes go through plasma-pa's GlobalService, which honours the configured
    // volume step and maximum and shows the volume OSD, exactly like the native applet.
    function volumeUp(small) {
        if (small) {
            GlobalService.volumeUpSmall();
        } else {
            GlobalService.volumeUp();
        }
    }

    function volumeDown(small) {
        if (small) {
            GlobalService.volumeDownSmall();
        } else {
            GlobalService.volumeDown();
        }
    }

    // Honour the system "audio volume feedback" setting, like the native applet.
    function playFeedback() {
        if (config.audioFeedback && hasSink) {
            feedback.play(sink.index);
        }
    }

    GlobalConfig {
        id: config
    }

    VolumeFeedback {
        id: feedback
    }
}
