import QtQuick
import org.kde.ksvg as KSvg
import QtQuick.Layouts
import org.kde.ksysguard.sensors as Sensors
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.plasmoid

Item {
    id: compactRepresentation

    property real catScaleFactorRaw: plasmoid.configuration.catScale || 1.0
    property real textScaleFactor:   plasmoid.configuration.textScale || 1.0
    property real catScaleFactor:    catScaleFactorRaw * 1.4

    readonly property bool useVertical: plasmoid.configuration.textBelowCat

    readonly property bool showDivider: plasmoid.configuration.showDivider

    // Spacing: -1 in config means auto (fill widget width)
    readonly property bool spacingIsAuto: plasmoid.configuration.customSpacing < 0
    readonly property real configuredSpacing: spacingIsAuto ? baseSpacing : plasmoid.configuration.customSpacing

    // Precomputed image-path arrays — one set per animation state
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

    // Angry when sensor >= threshold; threshold 0 = always angry (useful for testing)
    readonly property bool isAngry: plasmoid.configuration.angryEnabled
        && tempSensor.value >= plasmoid.configuration.angryTemp

    // ── Block sizes ──────────────────────────────────────────────────────────

    property real catBlockWidth:  (plasmoid.configuration.type !== 2) ? 32 * catScaleFactor : 0
    property real catBlockHeight: (plasmoid.configuration.type !== 2) ? 32 * catScaleFactor : 0
    property real textBlockWidth: (plasmoid.configuration.type !== 1) ? textMetrics.width + 16 * textScaleFactor : 0
    property real textBlockHeight:(plasmoid.configuration.type !== 1) ? 32 * textScaleFactor : 0
    // Horizontal layout: narrow column for a vertical bar; vertical layout: no column width needed
    property real dividerBlockWidth:  (!useVertical && showDivider) ? 8 : 0
    // Vertical layout: 1px row for the horizontal rule (rowSpacing provides all visual gap)
    property real dividerBlockHeight: (useVertical && showDivider) ? 1 : 0

    // Minimum gap per column-gap (2 gaps in horizontal 3-col layout)
    property real baseSpacing: 4

    // ── Minimum / preferred sizes reported to the panel ──────────────────────

    // Horizontal: cat + 2×gap + divider + text  (divider collapses to 0 when hidden)
    property real totalMinWidth: useVertical
        ? Math.max(catBlockWidth, textBlockWidth)
        : catBlockWidth + dividerBlockWidth + textBlockWidth + 2 * baseSpacing

    property real totalMinHeight: useVertical
        ? catBlockHeight + plasmoid.configuration.catExtraPadding + dividerBlockHeight + textBlockHeight
          + configuredSpacing * (showDivider ? 2 : 1)
        : Math.max(catBlockHeight, textBlockHeight)

    Layout.minimumWidth:    totalMinWidth
    Layout.minimumHeight:   totalMinHeight
    Layout.preferredWidth:  totalMinWidth
    Layout.preferredHeight: totalMinHeight
    Layout.maximumWidth:  -1
    // Vertical fixed: cap at natural content height. Vertical auto: uncap so widget fills panel height.
    Layout.maximumHeight: (useVertical && !spacingIsAuto) ? totalMinHeight : -1

    // ── Layout detection (used by parent context) ─────────────────────────────

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
            if (compactRepresentation.parent.width - catContainer.Layout.preferredWidth >= label.contentWidth)
                return CompactRepresentation.LayoutType.HorizontalDesktop
            if (compactRepresentation.parent.height - catContainer.Layout.preferredHeight >= label.contentHeight)
                return CompactRepresentation.LayoutType.VerticalDesktop
            return CompactRepresentation.LayoutType.IconOnly
        }
    }

    // ── Grid ─────────────────────────────────────────────────────────────────
    //
    // Horizontal: 3 columns — [cat(0) | divider(1) | text(2)] or swapped.
    //   columnSpacing = configuredSpacing when fixed; fills available width when auto.
    //   In fixed mode grid.width = natural content width; anchors.centerIn handles centering.
    //
    // Vertical: 1 column, 2–3 rows (cat, [divider,] text).
    //   Auto: rowSpacing fills available height (mirrors horizontal auto behaviour).
    //   Fixed: rowSpacing = configuredSpacing.

    GridLayout {
        id: grid
        anchors.centerIn: parent

        // In fixed-spacing mode, shrink to natural content size so centering handles the rest
        width: useVertical ? compactRepresentation.width
             : (spacingIsAuto ? compactRepresentation.width
                              : catBlockWidth + dividerBlockWidth + textBlockWidth + 2 * configuredSpacing)
        height: compactRepresentation.height

        columns: useVertical ? 1 : 3
        // 3 rows in vertical when divider is shown (cat, divider, text); 2 rows otherwise
        rows:    useVertical ? (showDivider ? 3 : 2) : 1

        // Auto: spread the available room equally across the 2 column gaps.
        // Fixed: use configuredSpacing directly.
        columnSpacing: {
            if (useVertical) return 0
            if (spacingIsAuto)
                return Math.max(baseSpacing,
                    (compactRepresentation.width - catBlockWidth - dividerBlockWidth - textBlockWidth) / 2)
            return configuredSpacing
        }
        // Horizontal: fixed baseSpacing between the single row's items.
        // Vertical fixed: use configuredSpacing.
        // Vertical auto: distribute available height equally across row gaps (mirrors horizontal auto).
        rowSpacing: {
            if (!useVertical) return baseSpacing
            if (spacingIsAuto) {
                var numGaps = showDivider ? 2 : 1
                var available = compactRepresentation.height
                    - catBlockHeight - plasmoid.configuration.catExtraPadding
                    - dividerBlockHeight - textBlockHeight
                return Math.max(baseSpacing, available / numGaps)
            }
            return configuredSpacing
        }

        // ── Cat ──────────────────────────────────────────────────────────────

        Item {
            id: catContainer
            visible: plasmoid.configuration.type !== 2

            // Horizontal: col 0 normal, col 2 swapped.
            // Vertical with divider: row 0/2; without divider: row 0/1.
            Layout.column: useVertical ? 0 : (plasmoid.configuration.swapOrder ? 2 : 0)
            Layout.row: useVertical
                ? (showDivider ? (plasmoid.configuration.swapOrder ? 2 : 0)
                               : (plasmoid.configuration.swapOrder ? 1 : 0))
                : 0
            Layout.alignment:      Qt.AlignVCenter | Qt.AlignHCenter
            Layout.preferredWidth:  32 * catScaleFactor
            Layout.preferredHeight: 32 * catScaleFactor
            Layout.minimumWidth:    32 * catScaleFactor
            Layout.minimumHeight:   32 * catScaleFactor
            Layout.maximumWidth:    32 * catScaleFactor
            Layout.maximumHeight:   32 * catScaleFactor
            // Extra margin between cat and divider in stacked layout — for symmetry testing.
            // Compensates for the text label's implicit top/bottom font metrics padding.
            Layout.topMargin:    (useVertical &&  plasmoid.configuration.swapOrder) ? plasmoid.configuration.catExtraPadding : 0
            Layout.bottomMargin: (useVertical && !plasmoid.configuration.swapOrder) ? plasmoid.configuration.catExtraPadding : 0

            KSvg.SvgItem {
                id: svgItem
                property int sourceIndex: 0
                anchors.fill: parent
                imagePath: imagePaths[0]
            }
        }

        // ── Divider ──────────────────────────────────────────────────────────
        // Horizontal layout: 1px-wide vertical bar centered in narrow column (like |).
        // Vertical layout: 1px-tall short horizontal dash centered in the row (like —).

        Item {
            id: dividerContainer
            visible: plasmoid.configuration.showDivider

            Layout.column: useVertical ? 0 : 1
            Layout.row:    useVertical ? 1 : 0
            Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter

            // Horizontal mode: narrow fixed-width column; vertical mode: full column width, fixed height
            Layout.preferredWidth:  useVertical ? Math.max(catBlockWidth, textBlockWidth) : dividerBlockWidth
            Layout.minimumWidth:    0
            Layout.maximumWidth:    useVertical ? Math.max(catBlockWidth, textBlockWidth) : dividerBlockWidth
            Layout.preferredHeight: useVertical ? dividerBlockHeight : Math.max(catBlockHeight, textBlockHeight)
            Layout.minimumHeight:   0
            Layout.maximumHeight:   useVertical ? dividerBlockHeight : Math.max(catBlockHeight, textBlockHeight)

            Rectangle {
                anchors.centerIn: parent
                // Horizontal layout: 1px vertical bar, height matches text glyph height (not full cell)
                // Vertical layout: short 24px horizontal dash
                width:  useVertical ? 24 : 1
                height: useVertical ? 1 : label.font.pixelSize
                color:  Kirigami.Theme.textColor
                opacity: 0.45
            }
        }

        // ── Text ─────────────────────────────────────────────────────────────

        PlasmaComponents3.Label {
            id: label
            text: totalSensor.formattedValue
            visible: plasmoid.configuration.type !== 1

            Layout.column: useVertical ? 0 : (plasmoid.configuration.swapOrder ? 0 : 2)
            Layout.row: useVertical
                ? (showDivider ? (plasmoid.configuration.swapOrder ? 0 : 2)
                               : (plasmoid.configuration.swapOrder ? 0 : 1))
                : 0
            Layout.alignment:      Qt.AlignVCenter | Qt.AlignHCenter
            Layout.preferredWidth:  textMetrics.width + 16 * textScaleFactor
            Layout.preferredHeight: 32 * textScaleFactor
            Layout.minimumWidth:    textMetrics.width + 16 * textScaleFactor
            Layout.minimumHeight:   32 * textScaleFactor
            Layout.maximumWidth:    textMetrics.width + 16 * textScaleFactor
            Layout.maximumHeight:   32 * textScaleFactor

            font.pixelSize:      32 * textScaleFactor * 0.8
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment:   Text.AlignVCenter
            renderType:          Text.NativeRendering

            // Colour shifts with CPU load for at-a-glance feedback
            color: {
                var v = totalSensor.value
                if (v >= 85) return Kirigami.Theme.negativeTextColor
                if (v >= 60) return Kirigami.Theme.neutralTextColor
                return Kirigami.Theme.textColor
            }
            Behavior on color { ColorAnimation { duration: 400 } }
        }

        TextMetrics {
            id: textMetrics
            font.pixelSize: label.font.pixelSize
            text: "100.0%"
        }

    }

    // ── Sensors ──────────────────────────────────────────────────────────────

    Sensors.Sensor {
        id: totalSensor
        sensorId: "cpu/all/usage"
        updateRateLimit: plasmoid.configuration.updateRateLimit
    }

    Sensors.Sensor {
        id: tempSensor
        sensorId: plasmoid.configuration.tempSensorId
        updateRateLimit: plasmoid.configuration.tempUpdateRate
    }

    // ── Animation timer ───────────────────────────────────────────────────────
    // Picks normal or angry asset set; actual cycle logic is identical.

    Timer {
        id: switchTimer
        repeat: true
        running: true
        interval: Math.ceil(5000 / Math.sqrt(totalSensor.value + 35) - 400)
        onTriggered: {
            if (svgItem.sourceIndex >= 5) svgItem.sourceIndex = 0
            var paths = isAngry ? angryImagePaths : imagePaths
            svgItem.imagePath = (totalSensor.value < plasmoid.configuration.idle)
                ? paths[0]
                : paths[svgItem.sourceIndex + 1]
            svgItem.sourceIndex++
        }
    }
}
