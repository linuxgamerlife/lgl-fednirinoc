import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ScrollView {
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

    clip: true

    ColumnLayout {
        width: parent.width
        spacing: 12

        Label {
            text: "NoctaZoom"
            font.pixelSize: 24
        }

        Label {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: "This plugin launches hyprmag through Noctalia IPC. Point the command field at your hyprmag binary if it is not in PATH."
        }

        Label {
            text: "Command"
        }

        TextField {
            Layout.preferredWidth: 200
            text: String(settingValue("command", "hyprmag"))
            placeholderText: "hyprmag"
            onEditingFinished: saveSetting("command", text.trim())
        }

        Label {
            text: "Shape"
        }

        ComboBox {
            Layout.preferredWidth: 200
            model: ["rounded-rect", "circle"]
            currentIndex: Math.max(0, model.indexOf(String(settingValue("shape", "rounded-rect"))))
            onActivated: saveSetting("shape", currentText)
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: 12
            rowSpacing: 8

            Label {
                text: "Radius"
            }

            TextField {
                Layout.preferredWidth: 200
                text: String(settingValue("radius", 200))
                inputMethodHints: Qt.ImhDigitsOnly
                onEditingFinished: saveSetting("radius", parseInt(text))
            }

            Label {
                text: "Width"
            }

            TextField {
                Layout.preferredWidth: 200
                text: String(settingValue("width", 500))
                inputMethodHints: Qt.ImhDigitsOnly
                onEditingFinished: saveSetting("width", parseInt(text))
            }

            Label {
                text: "Height"
            }

            TextField {
                Layout.preferredWidth: 200
                text: String(settingValue("height", 200))
                inputMethodHints: Qt.ImhDigitsOnly
                onEditingFinished: saveSetting("height", parseInt(text))
            }
        }

        Label {
            text: "Scale"
        }

        TextField {
            Layout.preferredWidth: 200
            text: String(settingValue("scale", 4))
            placeholderText: "4"
            inputMethodHints: Qt.ImhFormattedNumbersOnly
            onEditingFinished: saveSetting("scale", parseFloat(text))
        }

        CheckBox {
            Layout.fillWidth: true
            text: "Render inactive monitors"
            checked: Boolean(settingValue("renderInactive", false))
            onToggled: saveSetting("renderInactive", checked)
        }

        CheckBox {
            Layout.fillWidth: true
            text: "Grab keyboard"
            checked: Boolean(settingValue("grabKeyboard", false))
            onToggled: saveSetting("grabKeyboard", checked)
        }

        Label {
            text: "Extra CLI args"
        }

        TextField {
            Layout.preferredWidth: 200
            text: String(settingValue("extraArgs", ""))
            placeholderText: "Extra CLI args"
            onEditingFinished: saveSetting("extraArgs", text)
        }
    }
}
