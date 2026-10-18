/*
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import org.kde.plasma.plasma5support as P5Support

// Runs shell commands asynchronously and calls back with the result.
P5Support.DataSource {
    id: runner

    engine: "executable"
    connectedSources: []

    property var callbacks: ({})

    function exec(command, callback) {
        if (callback) {
            callbacks[command] = callback;
        }
        connectSource(command);
    }

    onNewData: (sourceName, data) => {
        disconnectSource(sourceName);
        const callback = callbacks[sourceName];
        delete callbacks[sourceName];
        if (callback) {
            callback(data["exit code"], data.stdout, data.stderr);
        }
    }
}
