import QtQuick
import QtQuick.Effects
import org.kde.ksvg as KSvg
import QtQuick.Layouts
import org.kde.ksysguard.sensors as Sensors
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.plasmoid

Item {
    id: compactRepresentation

    // ── Scale factors ──────────────────────────────────────────────────────────
    property real catScaleFactorRaw:   plasmoid.configuration.catScale  || 1.0
    property real textScaleFactor:     plasmoid.configuration.textScale  || 1.0
    property real tempScaleFactor:     plasmoid.configuration.tempScale  || 1.0
    property real catScaleFactor:      catScaleFactorRaw * 1.4
    readonly property real dividerScaleFactor: plasmoid.configuration.dividerScale || 1.0

    // ── Cached config reads (resolve the property-map lookup once) ───────────────
    readonly property bool useVertical:      plasmoid.configuration.textBelowCat === true
    readonly property bool showDivider:      plasmoid.configuration.showDivider === true
    readonly property bool swapOrder:        plasmoid.configuration.swapOrder === true
    readonly property int  displayType:      plasmoid.configuration.type
    readonly property int  dividerThickness: plasmoid.configuration.dividerThickness
    readonly property int  tempUnit:         plasmoid.configuration.tempUnit

    // Which elements are shown. displayType: 0=cat+cpu, 1=cat only, 2=cpu only, 3=no cat/cpu.
    readonly property bool showCat:  displayType === 0 || displayType === 1
    readonly property bool showCpu:  displayType === 0 || displayType === 2
    readonly property bool showTemp: plasmoid.configuration.showTemp === true

    // ── Spacing ─────────────────────────────────────────────────────────────────
    readonly property bool spacingIsAuto: plasmoid.configuration.customSpacing < 0
    readonly property real configuredSpacing: spacingIsAuto ? baseSpacing : plasmoid.configuration.customSpacing
    property real baseSpacing: 4

    // ── Visual sequence: visible items (cat, cpu, temp) in order, dividers between ─
    // "d1"/"d2" mark the dividers after the 1st/2nd item. Reversed when swapOrder.
    readonly property int visibleItemCount:    (showCat?1:0) + (showCpu?1:0) + (showTemp?1:0)
    readonly property int visibleDividerCount: showDivider ? Math.max(0, visibleItemCount - 1) : 0
    readonly property var sequence: {
        var items = []
        if (showCat)  items.push("cat")
        if (showCpu)  items.push("cpu")
        if (showTemp) items.push("temp")
        if (swapOrder) items.reverse()
        var seq = []
        for (var i = 0; i < items.length; i++) {
            if (i > 0 && showDivider) seq.push("d" + i)
            seq.push(items[i])
        }
        return seq
    }
    readonly property int cellCount:     sequence.length
    readonly property int gapCount:      Math.max(1, cellCount - 1)   // divisor guard for auto spacing
    readonly property int gapsForSizing: Math.max(0, cellCount - 1)   // real gap count for size reporting

    // ── Cat animation ───────────────────────────────────────────────────────────
    // The timer drives currentCatImage; the cat item just binds its imagePath to it.
    readonly property var imagePaths: {
        var p = [Qt.resolvedUrl("../images/my-idle-symbolic.svg")]
        for (var i = 0; i < 5; i++)
            p.push(Qt.resolvedUrl("../images/my-active-" + i + "-symbolic.svg"))
        return p
    }
    readonly property var angryImagePaths: {
        var p = [Qt.resolvedUrl("../images/my-idle-symbolic.svg")]  // no angry idle variant
        for (var i = 0; i < 5; i++)
            p.push(Qt.resolvedUrl("../images/my-active-" + i + "-symbolic_angry.svg"))
        return p
    }
    property int catFrameIndex: 0
    property string currentCatImage: imagePaths[0]

    // Angry when sensor >= threshold; threshold 0 = always angry (useful for testing)
    readonly property bool isAngry: (plasmoid.configuration.angryEnabled === true)
        && tempSensor.value >= plasmoid.configuration.angryTemp

    // ── Temperature formatting (sensor value is °C) ─────────────────────────────
    function formatTemp(c) {
        if (tempUnit === 1) return Math.round(c * 9 / 5 + 32) + "°F"
        if (tempUnit === 2) return Math.round(c + 273.15) + " K"
        return Math.round(c) + "°C"
    }
    function hasTempReading(c) {
        return c !== undefined && c !== null && !isNaN(c)
    }
    readonly property string tempText: hasTempReading(tempSensor.value) ? formatTemp(tempSensor.value) : "—"

    // ── Element box sizes ───────────────────────────────────────────────────────
    readonly property real catBox: 32 * catScaleFactor

    // CPU text box: fixed-width metric ("100.0%") avoids jitter as the value changes.
    readonly property real cpuBoxWidth:     cpuMetrics.width + 16 * textScaleFactor
    readonly property real cpuTextHeight:   Math.max(8, Math.ceil(cpuLabel.contentHeight))
    readonly property real cpuBlockHeight:  useVertical ? (cpuTextHeight || 32 * textScaleFactor) : 32 * textScaleFactor

    // Temp text box: tracks the actual string (temperature changes slowly → no jitter).
    readonly property real tempBoxWidth:     tempMetrics.width + 16 * tempScaleFactor
    readonly property real tempTextHeight:   Math.max(8, Math.ceil(tempLabel.contentHeight))
    readonly property real tempBlockHeight:  useVertical ? (tempTextHeight || 32 * tempScaleFactor) : 32 * tempScaleFactor

    // Per-element footprint (0 when hidden)
    readonly property real catW:  showCat  ? catBox         : 0
    readonly property real catH:  showCat  ? catBox         : 0
    readonly property real cpuW:  showCpu  ? cpuBoxWidth    : 0
    readonly property real cpuH:  showCpu  ? cpuBlockHeight : 0
    readonly property real tempW: showTemp ? tempBoxWidth   : 0
    readonly property real tempH: showTemp ? tempBlockHeight: 0

    readonly property real maxItemWidth:  Math.max(catW, cpuW, tempW)
    readonly property real maxItemHeight: Math.max(catH, cpuH, tempH)

    // Divider cell sizes
    readonly property real dividerBlockWidth:  (!useVertical && showDivider) ? (dividerThickness + 6) : 0
    readonly property real dividerBlockHeight: (useVertical && showDivider) ? dividerThickness + 10 : 0
    readonly property real dividerLength: Math.round(32 * dividerScaleFactor * 0.8)

    // ── Cat-divider symmetry pads (empirical) ───────────────────────────────────
    // Compensate for the cat SVG's internal whitespace so the divider sits centred
    // against the cat's divider-facing edge. Only applies when the cat actually has a
    // divider neighbour (the cat is always at an end of the line, so any divider is adjacent).
    readonly property bool catAdjacentToDivider: showCat && visibleDividerCount > 0
    readonly property int stackedCatPad: 0   // divider cell (+10) already provides visual separation
    readonly property int sideCatPad:    (catAdjacentToDivider && !useVertical) ? 22 : 0   // side-by-side

    // ── Total content sizes ─────────────────────────────────────────────────────
    readonly property real contentMainH: catW + cpuW + tempW + visibleDividerCount * dividerBlockWidth
    readonly property real contentMainV: catH + cpuH + tempH + visibleDividerCount * dividerBlockHeight

    // ── Minimum / preferred sizes reported to the panel ─────────────────────────
    property real totalMinWidth: useVertical
        ? maxItemWidth
        : contentMainH + sideCatPad + gapsForSizing * configuredSpacing
    property real totalMinHeight: useVertical
        ? contentMainV + gapsForSizing * configuredSpacing
        : maxItemHeight

    Layout.minimumWidth:    totalMinWidth
    Layout.minimumHeight:   totalMinHeight
    Layout.preferredWidth:  totalMinWidth
    Layout.preferredHeight: totalMinHeight
    Layout.maximumWidth:  -1
    // Vertical fixed: cap at natural content height. Vertical auto: uncap so widget fills panel height.
    Layout.maximumHeight: (useVertical && !spacingIsAuto) ? totalMinHeight : -1

    // ── Layout detection (used by parent context) ───────────────────────────────
    enum LayoutType {
        HorizontalPanel,
        VerticalPanel,
        HorizontalDesktop,
        VerticalDesktop,
        IconOnly
    }
    property int layoutForm
    Binding on layoutForm {
        delayed: true
        value: {
            if (root.inPanel)
                return root.isVertical ? CompactRepresentation.LayoutType.VerticalPanel
                                       : CompactRepresentation.LayoutType.HorizontalPanel
            if (compactRepresentation.parent.width - catContainer.Layout.preferredWidth >= cpuLabel.contentWidth)
                return CompactRepresentation.LayoutType.HorizontalDesktop
            if (compactRepresentation.parent.height - catContainer.Layout.preferredHeight >= cpuLabel.contentHeight)
                return CompactRepresentation.LayoutType.VerticalDesktop
            return CompactRepresentation.LayoutType.IconOnly
        }
    }

    // ── Grid ─────────────────────────────────────────────────────────────────────
    // One line of cells (horizontal row / vertical column). Each element computes its
    // index from `sequence`, so visibility, order and divider count all flow naturally.
    GridLayout {
        id: grid
        anchors.centerIn: parent

        // Fixed-spacing mode: shrink to natural content size so centring handles the rest.
        width: useVertical ? compactRepresentation.width
             : (spacingIsAuto ? compactRepresentation.width
                              : contentMainH + sideCatPad + gapsForSizing * configuredSpacing)
        height: useVertical ? (spacingIsAuto ? compactRepresentation.height : totalMinHeight)
                            : compactRepresentation.height

        columns: useVertical ? 1 : Math.max(1, cellCount)
        rows:    useVertical ? Math.max(1, cellCount) : 1

        // Auto: spread available room equally across all gaps. Fixed: configuredSpacing.
        columnSpacing: {
            if (useVertical) return 0
            if (spacingIsAuto)
                return Math.max(baseSpacing, (compactRepresentation.width - contentMainH - sideCatPad) / gapCount)
            return configuredSpacing
        }
        rowSpacing: {
            if (!useVertical) return baseSpacing
            if (spacingIsAuto) {
                if (cellCount <= 1) return 0
                return Math.max(baseSpacing, (compactRepresentation.height - contentMainV) / gapCount)
            }
            return configuredSpacing
        }

        // ── Cat ────────────────────────────────────────────────────────────────
        Item {
            id: catContainer
            visible: showCat
            readonly property int cellIndex: compactRepresentation.sequence.indexOf("cat")

            Layout.column: useVertical ? 0 : Math.max(0, cellIndex)
            Layout.row:    useVertical ? Math.max(0, cellIndex) : 0
            Layout.alignment:       Qt.AlignVCenter | Qt.AlignHCenter
            Layout.preferredWidth:  catBox
            Layout.preferredHeight: catBox
            Layout.minimumWidth:    catBox
            Layout.minimumHeight:   catBox
            Layout.maximumWidth:    catBox
            Layout.maximumHeight:   catBox
            // Margin on the cat's divider-facing edge (cat is always at an end of the line).
            Layout.topMargin:    (useVertical &&  swapOrder) ? stackedCatPad : 0
            Layout.bottomMargin: (useVertical && !swapOrder) ? stackedCatPad : 0
            Layout.leftMargin:   (!useVertical &&  swapOrder) ? sideCatPad : 0
            Layout.rightMargin:  (!useVertical && !swapOrder) ? sideCatPad : 0

            KSvg.SvgItem {
                anchors.fill: parent
                imagePath: currentCatImage

                layer.enabled: isAngry
                layer.effect: MultiEffect {
                    colorization: {
                        var ratio = Math.min(1, Math.max(0, (tempSensor.value - plasmoid.configuration.angryTemp) / 50))
                        return 0.20 + 0.75 * ratio
                    }
                    colorizationColor: {
                        var ratio = Math.min(1, Math.max(0, (tempSensor.value - plasmoid.configuration.angryTemp) / 50))
                        return Qt.rgba(1, 1 - ratio, 0, 1)
                    }
                    Behavior on colorization    { NumberAnimation { duration: 500 } }
                    Behavior on colorizationColor { ColorAnimation { duration: 500 } }
                }
            }
        }

        // ── Divider after item 1 ─────────────────────────────────────────────────
        Item {
            id: dividerA
            visible: compactRepresentation.sequence.indexOf("d1") >= 0
            readonly property int cellIndex: compactRepresentation.sequence.indexOf("d1")

            Layout.column: useVertical ? 0 : Math.max(0, cellIndex)
            Layout.row:    useVertical ? Math.max(0, cellIndex) : 0
            Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
            Layout.preferredWidth:  useVertical ? maxItemWidth : dividerBlockWidth
            Layout.maximumWidth:    useVertical ? maxItemWidth : dividerBlockWidth
            Layout.preferredHeight: useVertical ? dividerBlockHeight : maxItemHeight
            Layout.maximumHeight:   useVertical ? dividerBlockHeight : maxItemHeight

            Rectangle {
                anchors.centerIn: parent
                width:  useVertical ? dividerLength : dividerThickness
                height: useVertical ? dividerThickness : dividerLength
                color:  Kirigami.Theme.textColor
                opacity: 0.45
            }
        }

        // ── CPU percentage ───────────────────────────────────────────────────────
        PlasmaComponents3.Label {
            id: cpuLabel
            visible: showCpu
            readonly property int cellIndex: compactRepresentation.sequence.indexOf("cpu")
            text: totalSensor.formattedValue

            Layout.column: useVertical ? 0 : Math.max(0, cellIndex)
            Layout.row:    useVertical ? Math.max(0, cellIndex) : 0
            Layout.alignment:       Qt.AlignVCenter | Qt.AlignHCenter
            Layout.preferredWidth:  cpuBoxWidth
            Layout.minimumWidth:    cpuBoxWidth
            Layout.maximumWidth:    cpuBoxWidth
            Layout.preferredHeight: cpuBlockHeight
            Layout.minimumHeight:   cpuBlockHeight
            Layout.maximumHeight:   cpuBlockHeight

            font.pixelSize:      32 * textScaleFactor * 0.8
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment:   Text.AlignVCenter
            renderType:          Text.NativeRendering
            topPadding:          0
            bottomPadding:       0

            color: {
                var v = totalSensor.value
                if (v >= 85) return Kirigami.Theme.negativeTextColor
                if (v >= 60) return Kirigami.Theme.neutralTextColor
                return Kirigami.Theme.textColor
            }
            Behavior on color { ColorAnimation { duration: 400 } }
        }

        // ── Divider after item 2 ─────────────────────────────────────────────────
        Item {
            id: dividerB
            visible: compactRepresentation.sequence.indexOf("d2") >= 0
            readonly property int cellIndex: compactRepresentation.sequence.indexOf("d2")

            Layout.column: useVertical ? 0 : Math.max(0, cellIndex)
            Layout.row:    useVertical ? Math.max(0, cellIndex) : 0
            Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
            Layout.preferredWidth:  useVertical ? maxItemWidth : dividerBlockWidth
            Layout.maximumWidth:    useVertical ? maxItemWidth : dividerBlockWidth
            Layout.preferredHeight: useVertical ? dividerBlockHeight : maxItemHeight
            Layout.maximumHeight:   useVertical ? dividerBlockHeight : maxItemHeight

            Rectangle {
                anchors.centerIn: parent
                width:  useVertical ? dividerLength : dividerThickness
                height: useVertical ? dividerThickness : dividerLength
                color:  Kirigami.Theme.textColor
                opacity: 0.45
            }
        }

        // ── Temperature ──────────────────────────────────────────────────────────
        PlasmaComponents3.Label {
            id: tempLabel
            visible: showTemp
            readonly property int cellIndex: compactRepresentation.sequence.indexOf("temp")
            text: tempText

            Layout.column: useVertical ? 0 : Math.max(0, cellIndex)
            Layout.row:    useVertical ? Math.max(0, cellIndex) : 0
            Layout.alignment:       Qt.AlignVCenter | Qt.AlignHCenter
            Layout.preferredWidth:  tempBoxWidth
            Layout.minimumWidth:    tempBoxWidth
            Layout.maximumWidth:    tempBoxWidth
            Layout.preferredHeight: tempBlockHeight
            Layout.minimumHeight:   tempBlockHeight
            Layout.maximumHeight:   tempBlockHeight

            font.pixelSize:      32 * tempScaleFactor * 0.8
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment:   Text.AlignVCenter
            renderType:          Text.NativeRendering
            topPadding:          0
            bottomPadding:       0

            color: {
                var c = tempSensor.value
                if (c >= 85) return Kirigami.Theme.negativeTextColor
                if (c >= 70) return Kirigami.Theme.neutralTextColor
                return Kirigami.Theme.textColor
            }
            Behavior on color { ColorAnimation { duration: 400 } }
        }

        // Width metrics. Full font (family + size) so fixed text boxes match the rendered labels.
        TextMetrics { id: cpuMetrics;  font: cpuLabel.font;  text: "100.0%" }
        TextMetrics { id: tempMetrics; font: tempLabel.font; text: tempText }
    }

    // ── Sensors ──────────────────────────────────────────────────────────────────
    Sensors.Sensor {
        id: totalSensor
        enabled: showCpu || showCat
        sensorId: enabled ? "cpu/all/usage" : ""
        updateRateLimit: plasmoid.configuration.updateRateLimit
    }

    Sensors.Sensor {
        id: tempSensor
        enabled: showTemp || plasmoid.configuration.angryEnabled === true
        sensorId: enabled ? plasmoid.configuration.tempSensorId : ""
        updateRateLimit: plasmoid.configuration.tempUpdateRate
    }

    // ── Animation timer ───────────────────────────────────────────────────────────
    // Lower CPU = slower walk. Floor at 30ms and coerce a missing reading to 0 so the
    // interval can never become NaN/≤0 (which would make the Timer free-run).
    Timer {
        id: switchTimer
        repeat: true
        running: showCat
        interval: Math.max(30, Math.ceil(5000 / Math.sqrt((totalSensor.value || 0) + 35) - 400))
        onTriggered: {
            if (catFrameIndex >= 5) catFrameIndex = 0
            var paths = isAngry ? angryImagePaths : imagePaths
            currentCatImage = (totalSensor.value < plasmoid.configuration.idle)
                ? paths[0]
                : paths[catFrameIndex + 1]
            catFrameIndex++
        }
    }
}
