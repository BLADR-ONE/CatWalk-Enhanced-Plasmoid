import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    property alias cfg_idle: idleSlider.value
    property alias cfg_type: typeBox.currentIndex
    property alias cfg_updateRateLimit: updateRateLimitSpinBox.value
    property alias cfg_catScale: catScaleSlider.value
    property alias cfg_textScale: textScaleSlider.value
    property alias cfg_linkScales: linkCheckbox.checked

    // New config options
    property alias cfg_textBelowCat: textBelowCatCheckBox.checked
    property alias cfg_swapOrder: swapOrderCheckBox.checked

    Kirigami.FormLayout {
        id: root

        Controls.CheckBox {
            id: linkCheckbox
            Kirigami.FormData.label: i18n("Link sizes")
            text: i18n("Keep cat and text same size")
            checked: true
            onCheckedChanged: {
                if (checked) {
                    // When linking, sync text to cat
                    textScaleSlider.value = catScaleSlider.value
                }
            }
        }

        // Layout mode: side by side vs text below cat
        Controls.CheckBox {
            id: textBelowCatCheckBox
            Kirigami.FormData.label: i18n("Layout")
            text: i18n("Show text below cat (instead of side by side)")
            checked: false
        }

        // Swap order in both orientations
        Controls.CheckBox {
            id: swapOrderCheckBox
            text: i18n("Swap cat and text order")
            checked: false
        }

        RowLayout {
            Layout.fillWidth: true
            Kirigami.FormData.label: i18n("Cat size")
            Controls.Slider {
                Layout.fillWidth: true
                id: catScaleSlider
                from: 0.25
                to: 2.0
                value: 1.0
                stepSize: 0.05
                onValueChanged: {
                    if (linkCheckbox.checked) {
                        textScaleSlider.value = value
                    }
                }
            }
            Controls.Label {
                text: Math.round(catScaleSlider.value * 100) + "%"
                Layout.minimumWidth: textMetrics2.width
                Layout.minimumHeight: textMetrics2.height
                horizontalAlignment: Text.AlignRight
            }
            TextMetrics {
                id: textMetrics2
                text: "200%"
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Kirigami.FormData.label: i18n("Text size")
            Controls.Slider {
                Layout.fillWidth: true
                id: textScaleSlider
                from: 0.25
                to: 2.0
                value: 1.0
                stepSize: 0.05
                enabled: !linkCheckbox.checked
                onValueChanged: {
                    if (linkCheckbox.checked) {
                        catScaleSlider.value = value
                    }
                }
            }
            Controls.Label {
                text: Math.round(textScaleSlider.value * 100) + "%"
                Layout.minimumWidth: textMetrics3.width
                Layout.minimumHeight: textMetrics3.height
                horizontalAlignment: Text.AlignRight
            }
            TextMetrics {
                id: textMetrics3
                text: "200%"
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Kirigami.FormData.label: i18n("Idle threshold")
            Controls.Slider {
                Layout.fillWidth: true
                id: idleSlider
                from: 0
                to: 100
                stepSize: 1
            }
            Controls.Label {
                id: label
                text: idleSlider.value + "%"
                Layout.minimumWidth: textMetrics.width
                Layout.minimumHeight: textMetrics.height
                horizontalAlignment: Text.AlignRight
            }
            TextMetrics {
                id: textMetrics
                text: "199%"
            }
        }

        Controls.ComboBox {
            Layout.fillWidth: true
            Kirigami.FormData.label: i18n("Displaying items")
            id: typeBox
            model: [
                i18n("Character and percentage"),
                i18n("Character only"),
                i18n("Percentage only")
            ]
        }

        Controls.SpinBox {
            id: updateRateLimitSpinBox
            Layout.fillWidth: true
            Kirigami.FormData.label: i18nd(
                "KSysGuardSensorFaces",
                "Minimum Time Between Updates:"
            )
            from: 0
            to: 60000
            stepSize: 500
            editable: true
            textFromValue: function (value, locale) {
                if (value <= 0) {
                    return i18nd("KSysGuardSensorFaces", "No Limit")
                } else {
                    var seconds = value / 1000
                    if (seconds == 1) {
                        return i18nd("KSysGuardSensorFaces", "1 second")
                    } else {
                        return i18nd(
                            "KSysGuardSensorFaces",
                            "%1 seconds",
                            seconds
                        )
                    }
                }
            }
            valueFromText: function (value, locale) {
                var v = parseInt(value)
                if (isNaN(v)) {
                    return 0
                } else {
                    return v * 1000
                }
            }
        }
    }
}

