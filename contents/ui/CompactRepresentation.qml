import QtQuick
import org.kde.ksvg as KSvg
import QtQuick.Layouts
import org.kde.ksysguard.sensors as Sensors
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.plasmoid

Item {
    id: compactRepresentation

    // Raw values from sliders
    property real catScaleFactorRaw: plasmoid.configuration.catScale || 1.0
    property real textScaleFactor: plasmoid.configuration.textScale || 1.0

    // Make cat 1.4× relative to text: cat 100% ≙ previous 140%
    property real catScaleFactor: catScaleFactorRaw * 1.4

    // Use vertical layout when "text below cat" is checked
    readonly property bool useVertical: plasmoid.configuration.textBelowCat

    // Fixed intrinsic block sizes
    property real catBlockWidth: (plasmoid.configuration.type !== 2) ? 32 * catScaleFactor : 0
    property real catBlockHeight: (plasmoid.configuration.type !== 2) ? 32 * catScaleFactor : 0
    property real textBlockWidth: (plasmoid.configuration.type !== 1) ? textMetrics.width + 16 * textScaleFactor : 0
    property real textBlockHeight: (plasmoid.configuration.type !== 1) ? 32 * textScaleFactor : 0

    // Minimum size calculations depend on orientation
    property real baseSpacing: 4
    property real minSpacing: (catBlockWidth > 0 && textBlockWidth > 0) ? baseSpacing : 0

    // In horizontal: width = cat + text + spacing, height = max(cat, text)
    // In vertical: width = max(cat, text), height = cat + text + spacing
    property real totalMinWidth: useVertical
                                 ? Math.max(catBlockWidth, textBlockWidth)
                                 : (catBlockWidth + textBlockWidth + minSpacing)
    
    property real totalMinHeight: useVertical
                                  ? (catBlockHeight + textBlockHeight + minSpacing)
                                  : Math.max(catBlockHeight, textBlockHeight)

    Layout.minimumWidth: totalMinWidth
    Layout.minimumHeight: totalMinHeight
    Layout.preferredWidth: totalMinWidth
    Layout.preferredHeight: totalMinHeight
    Layout.maximumWidth: -1
    Layout.maximumHeight: useVertical ? totalMinHeight : -1

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
            if (root.inPanel) {
                return root.isVertical ? CompactRepresentation.LayoutType.VerticalPanel
                                       : CompactRepresentation.LayoutType.HorizontalPanel
            }
            if (compactRepresentation.parent.width - svgItem.Layout.preferredWidth >= label.contentWidth) {
                return CompactRepresentation.LayoutType.HorizontalDesktop
            }
            if (compactRepresentation.parent.height - svgItem.Layout.preferredHeight >= label.contentHeight) {
                return CompactRepresentation.LayoutType.VerticalDesktop
            }
            return CompactRepresentation.LayoutType.IconOnly
        }
    }

    GridLayout {
        id: grid
        anchors.centerIn: parent

        width: compactRepresentation.width
        height: compactRepresentation.height

        // Dynamic spacing only in horizontal mode
        readonly property real extraSpace: useVertical 
                                          ? 0 
                                          : Math.max(0, width - totalMinWidth)

        // Fixed minimal spacing in vertical, dynamic in horizontal
        rowSpacing: baseSpacing
        columnSpacing: useVertical ? 0 : (minSpacing + extraSpace)

        // Don't use flow when we have explicit row/column positioning
        columns: useVertical ? 1 : 2
        rows: useVertical ? 2 : 1

        KSvg.SvgItem {
            property int sourceIndex: 0
            id: svgItem
            opacity: 1

            // Explicit positioning based on orientation and swap
            Layout.row: {
                if (useVertical) {
                    return plasmoid.configuration.swapOrder ? 1 : 0
                } else {
                    return 0
                }
            }
            
            Layout.column: {
                if (useVertical) {
                    return 0
                } else {
                    return plasmoid.configuration.swapOrder ? 1 : 0
                }
            }

            Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter

            Layout.preferredWidth: 32 * catScaleFactor
            Layout.preferredHeight: 32 * catScaleFactor
            Layout.minimumWidth: 32 * catScaleFactor
            Layout.minimumHeight: 32 * catScaleFactor
            Layout.maximumWidth: 32 * catScaleFactor
            Layout.maximumHeight: 32 * catScaleFactor

            visible: plasmoid.configuration.type !== 2
            imagePath: Qt.resolvedUrl("../images/my-idle-symbolic.svg")
        }

        PlasmaComponents3.Label {
            id: label
            text: totalSensor.formattedValue
            visible: plasmoid.configuration.type !== 1

            // Opposite row/column of cat
            Layout.row: {
                if (useVertical) {
                    return plasmoid.configuration.swapOrder ? 0 : 1
                } else {
                    return 0
                }
            }
            
            Layout.column: {
                if (useVertical) {
                    return 0
                } else {
                    return plasmoid.configuration.swapOrder ? 0 : 1
                }
            }

            Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter

            Layout.preferredWidth: textMetrics.width + 16 * textScaleFactor
            Layout.preferredHeight: 32 * textScaleFactor
            Layout.minimumWidth: textMetrics.width + 16 * textScaleFactor
            Layout.minimumHeight: 32 * textScaleFactor
            Layout.maximumWidth: textMetrics.width + 16 * textScaleFactor
            Layout.maximumHeight: 32 * textScaleFactor

            font.pixelSize: 32 * textScaleFactor * 0.8
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            renderType: Text.NativeRendering
        }

        TextMetrics {
            id: textMetrics
            font.pixelSize: label.font.pixelSize
            text: "100,0%"
        }
    }

    Sensors.Sensor {
        id: totalSensor
        sensorId: "cpu/all/usage"
        updateRateLimit: plasmoid.configuration.updateRateLimit
    }

    Timer {
        id: switchTimer
        repeat: true
        running: true
        interval: Math.ceil(5000 / Math.sqrt(totalSensor.value + 35) - 400)
        onTriggered: {
            if (svgItem.sourceIndex == 5) {
                svgItem.sourceIndex = 0
            }
            svgItem.imagePath = (totalSensor.value < plasmoid.configuration.idle)
                ? Qt.resolvedUrl("../images/my-idle-symbolic.svg")
                : Qt.resolvedUrl("../images/my-active-" + svgItem.sourceIndex + "-symbolic.svg")
            svgItem.sourceIndex += 1
        }
    }
}

