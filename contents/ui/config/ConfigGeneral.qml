import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM
import org.kde.ksysguard.sensors as Sensors

KCM.SimpleKCM {
    property alias cfg_idle:            idleSlider.value
    property alias cfg_type:            typeBox.currentIndex
    property alias cfg_updateRateLimit: updateRateLimitSpinBox.value
    property alias cfg_catScale:        catScaleSlider.value
    property alias cfg_textScale:       textScaleSlider.value
    property alias cfg_linkScales:      linkCheckbox.checked
    property alias cfg_textBelowCat:    textBelowCatCheckBox.checked
    property alias cfg_swapOrder:       swapOrderCheckBox.checked
    property alias cfg_showDivider:     showDividerCheckBox.checked
    property alias cfg_angryEnabled:    angryCheckbox.checked
    property alias cfg_angryTemp:       angryTempSlider.value
    property alias cfg_tempSensorId:    tempSensorField.text
    property alias cfg_tempUpdateRate:  tempUpdateRateSpinBox.value
    property alias cfg_dividerScale:     dividerScaleSlider.value
    property alias cfg_dividerThickness: dividerThicknessSpinBox.value

    // customSpacing: -1 = auto, ≥0 = fixed px. Cannot use property alias because
    // the value toggles between -1 and a slider value — no single control maps to it.
    property int cfg_customSpacing: -1

    // The config dialog assigns a cfg_<key>Default for EVERY schema key when the page loads
    // (used for the reset-to-default button and the "modified" indicator). They are NOT
    // auto-created on the page object, so each must be declared here or the framework warns
    // "does not have a property called cfg_<key>Default". Values mirror config/main.xml.
    property int    cfg_idleDefault:             0
    property int    cfg_typeDefault:             0
    property int    cfg_updateRateLimitDefault:  1000
    property real   cfg_catScaleDefault:         1.0
    property real   cfg_textScaleDefault:        1.0
    property bool   cfg_linkScalesDefault:       true
    property bool   cfg_textBelowCatDefault:     false
    property bool   cfg_swapOrderDefault:        false
    property bool   cfg_showDividerDefault:      false
    property int    cfg_customSpacingDefault:    -1
    property bool   cfg_angryEnabledDefault:     true
    property int    cfg_angryTempDefault:        80
    property string cfg_tempSensorIdDefault:     "cpu/cpu0/temperature"
    property int    cfg_tempUpdateRateDefault:   5000
    property real   cfg_dividerScaleDefault:     1.0
    property int    cfg_dividerThicknessDefault: 1

    // Spacing UI mode: 0=auto, 1=slider, 2=manual. Not persisted — initialised from cfg_customSpacing.
    property int spacingMode: 0
    Component.onCompleted: {
        spacingMode = cfg_customSpacing < 0 ? 0 : 1
        spacingModeGroup.buttons = [spacingAutoRadio, spacingSliderRadio, spacingManualRadio]
        if (spacingMode === 0) spacingAutoRadio.checked = true
        else if (spacingMode === 1) spacingSliderRadio.checked = true
        else spacingManualRadio.checked = true
    }

    // Live sensor preview (reads whatever is typed in tempSensorField)
    Sensors.Sensor {
        id: previewSensor
        sensorId: tempSensorField.text
        updateRateLimit: cfg_tempUpdateRate
    }

    Controls.ButtonGroup { id: spacingModeGroup }

    Kirigami.FormLayout {
        id: formRoot

        // ── Layout ───────────────────────────────────────────────────────────

        Controls.CheckBox {
            id: linkCheckbox
            Kirigami.FormData.label: i18n("Link sizes")
            text: i18n("Keep cat and text same size")
            checked: true
            onCheckedChanged: {
                if (checked) {
                    textScaleSlider.value = catScaleSlider.value
                    dividerScaleSlider.value = catScaleSlider.value
                }
            }
        }

        Controls.CheckBox {
            id: textBelowCatCheckBox
            Kirigami.FormData.label: i18n("Layout")
            text: i18n("Show text below cat (instead of side by side)")
        }

        Controls.CheckBox {
            id: swapOrderCheckBox
            text: i18n("Swap cat and text order")
        }

        Controls.CheckBox {
            id: showDividerCheckBox
            text: i18n("Show divider between cat and text")
        }

        // ── Spacing ──────────────────────────────────────────────────────────

        Kirigami.Separator {
            Kirigami.FormData.label: i18n("Spacing")
            Kirigami.FormData.isSection: true
            Layout.fillWidth: true
        }

        Controls.RadioButton {
            id: spacingAutoRadio
            Kirigami.FormData.label: i18n("Mode")
            text: i18n("Automatic — fill available space")
            checked: true
            onToggled: if (checked) { spacingMode = 0; cfg_customSpacing = -1 }
        }

        Controls.RadioButton {
            id: spacingSliderRadio
            text: i18n("Slider")
            onToggled: if (checked) { spacingMode = 1; cfg_customSpacing = Math.round(spacingSlider.value) }
        }

        Controls.RadioButton {
            id: spacingManualRadio
            text: i18n("Manual (exact pixels)")
            onToggled: if (checked) { spacingMode = 2; var v = parseInt(spacingManualField.text) || 0; cfg_customSpacing = v }
        }

        RowLayout {
            visible: spacingMode === 1
            Layout.fillWidth: true
            Kirigami.FormData.label: i18n("Gap")

            Controls.Slider {
                id: spacingSlider
                Layout.fillWidth: true
                from: 0; to: 500; stepSize: 1
                value: cfg_customSpacing >= 0 ? cfg_customSpacing : 8
                onMoved: cfg_customSpacing = Math.round(value)
            }
            Controls.Label {
                text: Math.round(spacingSlider.value) + " px"
                Layout.minimumWidth: spacingLabelMetrics.width
                horizontalAlignment: Text.AlignRight
            }
            TextMetrics { id: spacingLabelMetrics; text: "500 px" }
        }

        RowLayout {
            visible: spacingMode === 2
            Layout.fillWidth: true
            Kirigami.FormData.label: i18n("Gap")

            Controls.TextField {
                id: spacingManualField
                Layout.fillWidth: true
                inputMethodHints: Qt.ImhDigitsOnly
                validator: IntValidator { bottom: 0; top: 500 }
                // No declarative `text:` binding on a value we also write back to — that
                // forms a binding loop. Seed imperatively, and only react to user edits.
                Component.onCompleted: text = cfg_customSpacing >= 0 ? cfg_customSpacing.toString() : "8"
                onVisibleChanged: if (visible) text = cfg_customSpacing >= 0 ? cfg_customSpacing.toString() : "8"
                onTextEdited: {
                    var v = parseInt(text)
                    if (!isNaN(v) && v >= 0 && v <= 500) cfg_customSpacing = v
                }
            }
            Controls.Label { text: i18n("px") }
        }

        // ── Sizing ───────────────────────────────────────────────────────────

        Kirigami.Separator {
            Kirigami.FormData.label: i18n("Sizing")
            Kirigami.FormData.isSection: true
            Layout.fillWidth: true
        }

        RowLayout {
            Layout.fillWidth: true
            Kirigami.FormData.label: i18n("Cat size")
            Controls.Slider {
                id: catScaleSlider
                Layout.fillWidth: true
                from: 0.25; to: 2.0; stepSize: 0.05; value: 1.0
                onValueChanged: { if (linkCheckbox.checked) { textScaleSlider.value = value; dividerScaleSlider.value = value } }
            }
            Controls.Label {
                text: Math.round(catScaleSlider.value * 100) + "%"
                Layout.minimumWidth: scaleLabelMetrics.width
                horizontalAlignment: Text.AlignRight
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Kirigami.FormData.label: i18n("Text size")
            Controls.Slider {
                id: textScaleSlider
                Layout.fillWidth: true
                from: 0.25; to: 2.0; stepSize: 0.05; value: 1.0
                enabled: !linkCheckbox.checked
                onValueChanged: { if (linkCheckbox.checked) { catScaleSlider.value = value; dividerScaleSlider.value = value } }
            }
            Controls.Label {
                text: Math.round(textScaleSlider.value * 100) + "%"
                Layout.minimumWidth: scaleLabelMetrics.width
                horizontalAlignment: Text.AlignRight
            }
        }

        TextMetrics { id: scaleLabelMetrics; text: "200%" }

        RowLayout {
            Layout.fillWidth: true
            Kirigami.FormData.label: i18n("Divider size")

            Controls.Slider {
                id: dividerScaleSlider
                Layout.fillWidth: true
                from: 0.25; to: 2.0; stepSize: 0.05; value: 1.0
                enabled: !linkCheckbox.checked
                onValueChanged: { if (linkCheckbox.checked) { catScaleSlider.value = value; textScaleSlider.value = value } }
            }
            Controls.Label {
                text: Math.round(dividerScaleSlider.value * 100) + "%"
                Layout.minimumWidth: scaleLabelMetrics.width
                horizontalAlignment: Text.AlignRight
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Kirigami.FormData.label: i18n("Divider thickness")

            Controls.SpinBox {
                id: dividerThicknessSpinBox
                from: 1; to: 10; stepSize: 1; editable: true
            }
            Controls.Label { text: i18n("px") }
        }

        // ── Sensor ───────────────────────────────────────────────────────────

        Kirigami.Separator {
            Kirigami.FormData.label: i18n("Sensor")
            Kirigami.FormData.isSection: true
            Layout.fillWidth: true
        }

        RowLayout {
            Layout.fillWidth: true
            Kirigami.FormData.label: i18n("Idle threshold")
            Controls.Slider {
                id: idleSlider
                Layout.fillWidth: true
                from: 0; to: 100; stepSize: 1
            }
            Controls.Label {
                text: idleSlider.value + "%"
                Layout.minimumWidth: idleMetrics.width
                horizontalAlignment: Text.AlignRight
            }
            TextMetrics { id: idleMetrics; text: "100%" }
        }

        Controls.ComboBox {
            id: typeBox
            Layout.fillWidth: true
            Kirigami.FormData.label: i18n("Display")
            model: [
                i18n("Character and percentage"),
                i18n("Character only"),
                i18n("Percentage only")
            ]
        }

        Controls.SpinBox {
            id: updateRateLimitSpinBox
            Layout.fillWidth: true
            Kirigami.FormData.label: i18n("CPU update rate")
            from: 0; to: 60000; stepSize: 500; editable: true
            textFromValue: function(value, locale) {
                if (value <= 0) return i18n("No limit")
                var s = value / 1000
                return (s === 1) ? i18n("1 second") : i18n("%1 seconds", s)
            }
            valueFromText: function(value, locale) {
                var v = parseInt(value)
                return isNaN(v) ? 0 : v * 1000
            }
        }

        // ── Angry Cat ────────────────────────────────────────────────────────

        Kirigami.Separator {
            Kirigami.FormData.label: i18n("Angry Cat")
            Kirigami.FormData.isSection: true
            Layout.fillWidth: true
        }

        Controls.CheckBox {
            id: angryCheckbox
            Kirigami.FormData.label: i18n("Enable")
            text: i18n("Use angry frames when temperature reaches threshold")
        }

        RowLayout {
            Layout.fillWidth: true
            enabled: angryCheckbox.checked
            Kirigami.FormData.label: i18n("Threshold")

            Controls.Slider {
                id: angryTempSlider
                Layout.fillWidth: true
                from: 0; to: 120; stepSize: 1; value: 80
            }
            Controls.Label {
                text: angryTempSlider.value === 0 ? i18n("always") : (angryTempSlider.value + "°C")
                Layout.minimumWidth: angryTempMetrics.width
                horizontalAlignment: Text.AlignRight
            }
            TextMetrics { id: angryTempMetrics; text: "120°C" }
        }

        RowLayout {
            Layout.fillWidth: true
            enabled: angryCheckbox.checked
            Kirigami.FormData.label: i18n("Temp sensor")

            Controls.TextField {
                id: tempSensorField
                Layout.fillWidth: true
                placeholderText: "cpu/cpu0/temperature"
            }
        }

        // Live readout — immediate feedback on whether the sensor ID is correct
        Controls.Label {
            enabled: angryCheckbox.checked
            Kirigami.FormData.label: i18n("Reading")
            text: previewSensor.value > 0
                ? i18n("%1 °C", Math.round(previewSensor.value))
                : i18n("No data — check sensor ID")
            color: previewSensor.value > 0 ? Kirigami.Theme.positiveTextColor
                                           : Kirigami.Theme.neutralTextColor
        }

        Controls.Label {
            enabled: angryCheckbox.checked
            Kirigami.FormData.label: " "
            text: i18n("Find sensor IDs in KDE System Monitor › Sensors tab, right-click a sensor → Copy sensor name")
            wrapMode: Text.WordWrap
            Layout.maximumWidth: 340
            font.italic: true
            opacity: 0.6
        }

        Controls.SpinBox {
            id: tempUpdateRateSpinBox
            Layout.fillWidth: true
            enabled: angryCheckbox.checked
            Kirigami.FormData.label: i18n("Temp update rate")
            from: 500; to: 60000; stepSize: 500; editable: true
            textFromValue: function(value, locale) {
                var s = value / 1000
                return (s === 1) ? i18n("1 second") : i18n("%1 seconds", s)
            }
            valueFromText: function(text, locale) {
                var v = parseFloat(text)
                return isNaN(v) ? 5000 : Math.round(v * 1000)
            }
        }
    }
}
