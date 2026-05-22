import QtQuick
import org.kde.ksvg as KSvg
import QtQuick.Layouts
import org.kde.ksysguard.sensors as Sensors
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.plasmoid

Item {
    id: compactRepresentation

    property real catScaleFactorRaw:   plasmoid.configuration.catScale || 1.0
    property real textScaleFactor:     plasmoid.configuration.textScale || 1.0
    property real catScaleFactor:      catScaleFactorRaw * 1.4
    readonly property real dividerScaleFactor: plasmoid.configuration.dividerScale || 1.0

    readonly property bool useVertical: plasmoid.configuration.textBelowCat === true

    readonly property bool showDivider: plasmoid.configuration.showDivider === true

    // Cached config reads — referenced many times in layout bindings, so resolve the
    // property-map lookup once instead of on every binding re-evaluation.
    readonly property bool swapOrder:        plasmoid.configuration.swapOrder === true
    readonly property int  displayType:      plasmoid.configuration.type
    readonly property int  dividerThickness: plasmoid.configuration.dividerThickness

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
    readonly property bool isAngry: (plasmoid.configuration.angryEnabled === true)
        && tempSensor.value >= plasmoid.configuration.angryTemp

    // ── Block sizes ──────────────────────────────────────────────────────────

    readonly property real catBox:       32 * catScaleFactor                      // cat cell edge (square)
    readonly property real textBoxWidth: textMetrics.width + 16 * textScaleFactor  // text cell width

    property real catBlockWidth:  (displayType !== 2) ? catBox : 0
    property real catBlockHeight: (displayType !== 2) ? catBox : 0
    property real textBlockWidth: (displayType !== 1) ? textBoxWidth : 0
    // Vertical layout shrinks the text cell to the glyphs' ink height so the stacked text has
    // no empty space above/below; horizontal keeps the full 32px cell height.
    property real textBlockHeight: (displayType === 1) ? 0
        : (useVertical ? (textInkHeight || 32 * textScaleFactor)
                       : 32 * textScaleFactor)
    property real dividerBlockWidth:  (!useVertical && showDivider) ? (dividerThickness + 6) : 0
    property real dividerBlockHeight: (useVertical && showDivider) ? dividerThickness : 0

    property real baseSpacing: 4
    readonly property real maxBlockWidth:  Math.max(catBlockWidth, textBlockWidth)
    readonly property real maxBlockHeight: Math.max(catBlockHeight, textBlockHeight)
    readonly property real dividerLength: Math.round(32 * dividerScaleFactor * 0.8)

    // Cat-divider symmetry padding — empirically-found fixed values that compensate
    // for any residual asymmetry so the divider sits centred.
    readonly property int stackedCatPad: 0    // text-below-cat layout (fine-tune if off-centre)
    readonly property int sideCatPad: !useVertical ? 22 : 0   // side-by-side layout

    // Tight text metrics (vertical layout): the digits' actual ink height, and the empty
    // vertical space (font leading + ascent/descent gap) to trim with negative padding.
    readonly property real textInkHeight:    Math.ceil(textMetrics.tightBoundingRect.height)
    readonly property real verticalTextTrim: Math.max(0, (label.contentHeight - textInkHeight) / 2)

    // ── Minimum / preferred sizes reported to the panel ──────────────────────

    // Horizontal: cat + 2×gap + divider + text  (divider collapses to 0 when hidden)
    property real totalMinWidth: useVertical
        ? Math.max(catBlockWidth, textBlockWidth)
        : catBlockWidth + dividerBlockWidth + textBlockWidth + 2 * baseSpacing + sideCatPad

    property real totalMinHeight: useVertical
        ? catBlockHeight + stackedCatPad + dividerBlockHeight + textBlockHeight
          + configuredSpacing * (showDivider ? 2 : 1)
        : maxBlockHeight

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
                              : catBlockWidth + dividerBlockWidth + textBlockWidth + 2 * configuredSpacing + sideCatPad)
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
                    (compactRepresentation.width - catBlockWidth - dividerBlockWidth - textBlockWidth - sideCatPad) / 2)
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
                    - catBlockHeight - stackedCatPad
                    - dividerBlockHeight - textBlockHeight
                return Math.max(baseSpacing, available / numGaps)
            }
            return configuredSpacing
        }

        // ── Cat ──────────────────────────────────────────────────────────────

        Item {
            id: catContainer
            visible: displayType !== 2

            // Horizontal: col 0 normal, col 2 swapped.
            // Vertical with divider: row 0/2; without divider: row 0/1.
            Layout.column: useVertical ? 0 : (swapOrder ? 2 : 0)
            Layout.row: useVertical
                ? (showDivider ? (swapOrder ? 2 : 0)
                               : (swapOrder ? 1 : 0))
                : 0
            Layout.alignment:      Qt.AlignVCenter | Qt.AlignHCenter
            Layout.preferredWidth:  catBox
            Layout.preferredHeight: catBox
            Layout.minimumWidth:    catBox
            Layout.minimumHeight:   catBox
            Layout.maximumWidth:    catBox
            Layout.maximumHeight:   catBox
            // Margin on the cat's divider-facing edge, compensating for the text label's
            // implicit font-metrics padding (stackedCatPad / sideCatPad).
            Layout.topMargin:    (useVertical &&  swapOrder) ? stackedCatPad : 0
            Layout.bottomMargin: (useVertical && !swapOrder) ? stackedCatPad : 0
            Layout.leftMargin:   (!useVertical &&  swapOrder) ? sideCatPad : 0
            Layout.rightMargin:  (!useVertical && !swapOrder) ? sideCatPad : 0

            KSvg.SvgItem {
                id: svgItem
                property int sourceIndex: 0
                anchors.fill: parent
                imagePath: imagePaths[0]
            }
        }

        // ── Divider ──────────────────────────────────────────────────────────
        // Horizontal: vertical bar (thickness × dividerLength), centered in narrow column.
        // Vertical: horizontal dash (dividerLength × thickness), centered in 1-row slot.

        Item {
            id: dividerContainer
            visible: showDivider

            Layout.column: useVertical ? 0 : 1
            Layout.row:    useVertical ? 1 : 0
            Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter

            Layout.preferredWidth:  useVertical ? maxBlockWidth : dividerBlockWidth
            Layout.minimumWidth:    0
            Layout.maximumWidth:    useVertical ? maxBlockWidth : dividerBlockWidth
            Layout.preferredHeight: useVertical ? dividerBlockHeight : maxBlockHeight
            Layout.minimumHeight:   0
            Layout.maximumHeight:   useVertical ? dividerBlockHeight : maxBlockHeight

            Rectangle {
                anchors.centerIn: parent
                width:  useVertical ? dividerLength : dividerThickness
                height: useVertical ? dividerThickness : dividerLength
                color:  Kirigami.Theme.textColor
                opacity: 0.45
            }
        }

        // ── Text ─────────────────────────────────────────────────────────────

        PlasmaComponents3.Label {
            id: label
            text: totalSensor.formattedValue
            visible: displayType !== 1

            Layout.column: useVertical ? 0 : (swapOrder ? 0 : 2)
            Layout.row: useVertical
                ? (showDivider ? (swapOrder ? 0 : 2)
                               : (swapOrder ? 0 : 1))
                : 0
            Layout.alignment:      Qt.AlignVCenter | Qt.AlignHCenter
            Layout.preferredWidth:  textBoxWidth
            Layout.preferredHeight: textBlockHeight
            Layout.minimumWidth:    textBoxWidth
            Layout.minimumHeight:   textBlockHeight
            Layout.maximumWidth:    textBoxWidth
            Layout.maximumHeight:   textBlockHeight

            font.pixelSize:      32 * textScaleFactor * 0.8
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment:   Text.AlignVCenter
            renderType:          Text.NativeRendering
            // Stacked layout: pull the cell in by the font's non-ink vertical space (leading +
            // the gap between the glyph ink and the font ascent/descent) so it hugs the digits.
            // Negative padding lets that empty space overflow the cell instead of inflating it.
            topPadding:    useVertical ? -verticalTextTrim : 0
            bottomPadding: useVertical ? -verticalTextTrim : 0

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
            font: label.font          // full font (family + size) so tightBoundingRect is accurate
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
        // Lower CPU = slower walk. Floor at 30ms and coerce a missing reading to 0 so the
        // interval can never become NaN/≤0 (which would make the Timer free-run).
        interval: Math.max(30, Math.ceil(5000 / Math.sqrt((totalSensor.value || 0) + 35) - 400))
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
