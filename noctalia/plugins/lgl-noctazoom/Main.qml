import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Services.UI

Item {
    property var pluginApi: null

    readonly property var pluginSettings: pluginApi?.pluginSettings || ({})
    readonly property var defaultSettings: pluginApi?.manifest?.metadata?.defaultSettings || ({})

    function settingValue(key, fallback) {
        const fromUser = pluginSettings[key];
        if (fromUser !== undefined && fromUser !== null && fromUser !== "")
            return fromUser;

        const fromDefault = defaultSettings[key];
        if (fromDefault !== undefined && fromDefault !== null && fromDefault !== "")
            return fromDefault;

        return fallback;
    }

    function saveSetting(key, value) {
        if (!pluginApi)
            return;

        pluginApi.pluginSettings[key] = value;
        pluginApi.saveSettings();
    }

    function parseExtraArgs(raw) {
        if (!raw)
            return [];

        return raw.split(/\s+/).filter(token => token.length > 0);
    }

    function buildCommand() {
        const command = [String(settingValue("command", "hyprmag"))];

        command.push("--shape", String(settingValue("shape", "rounded-rect")));
        command.push("--radius", String(settingValue("radius", 200)));
        command.push("--scale", String(settingValue("scale", 4)));

        const width = Number(settingValue("width", 500));
        const height = Number(settingValue("height", 200));
        if (width > 0 && height > 0) {
            command.push("--width", String(width));
            command.push("--height", String(height));
        }

        if (Boolean(settingValue("renderInactive", false)))
            command.push("--render-inactive");

        if (Boolean(settingValue("grabKeyboard", false)))
            command.push("--grab-keyboard");

        return command.concat(parseExtraArgs(String(settingValue("extraArgs", ""))));
    }

    function startZoom() {
        hyprmagProcess.command = buildCommand();
        hyprmagProcess.running = true;
    }

    function stopZoom() {
        hyprmagProcess.running = false;
    }

    function restartZoom() {
        stopZoom();
        startZoom();
    }

    Process {
        id: hyprmagProcess

        stdout: StdioCollector {
            onStreamFinished: if (text.trim().length > 0) console.log("[lgl-noctazoom][stdout]", text.trim())
        }

        stderr: StdioCollector {
            onStreamFinished: if (text.trim().length > 0) console.log("[lgl-noctazoom][stderr]", text.trim())
        }

        onStarted: {
            ToastService.showNotice("NoctaZoom started");
            console.log("[lgl-noctazoom] started:", command.join(" "));
        }

        onExited: (exitCode, exitStatus) => {
            console.log("[lgl-noctazoom] exited:", exitCode, exitStatus);
        }
    }

    IpcHandler {
        target: "plugin:lgl-noctazoom"

        function toggle() {
            if (hyprmagProcess.running)
                stopZoom();
            else
                startZoom();
        }

        function start() {
            startZoom();
        }

        function stop() {
            stopZoom();
        }

        function restart() {
            restartZoom();
        }

        function setShape(shape) {
            if (shape !== "circle" && shape !== "rounded-rect") {
                ToastService.showError("Shape must be circle or rounded-rect");
                return;
            }

            saveSetting("shape", shape);
            if (hyprmagProcess.running)
                restartZoom();
        }

        function setSize(width, height) {
            const parsedWidth = parseInt(width);
            const parsedHeight = parseInt(height);
            if (Number.isNaN(parsedWidth) || Number.isNaN(parsedHeight) || parsedWidth <= 0 || parsedHeight <= 0) {
                ToastService.showError("Width and height must be positive integers");
                return;
            }

            saveSetting("width", parsedWidth);
            saveSetting("height", parsedHeight);
            if (hyprmagProcess.running)
                restartZoom();
        }

        function setScale(scale) {
            const parsedScale = parseFloat(scale);
            if (Number.isNaN(parsedScale) || parsedScale < 0.5 || parsedScale > 10.0) {
                ToastService.showError("Scale must be between 0.5 and 10");
                return;
            }

            saveSetting("scale", parsedScale);
            if (hyprmagProcess.running)
                restartZoom();
        }
    }
}
