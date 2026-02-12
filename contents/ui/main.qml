import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.plasma5support as P5Support

PlasmoidItem {
    id: root
    property bool allowsDesktopPlacement: false
    readonly property bool inPanel: [PlasmaCore.Types.TopEdge, PlasmaCore.Types.RightEdge, PlasmaCore.Types.BottomEdge, PlasmaCore.Types.LeftEdge].includes(
        Plasmoid.location)
    readonly property bool isVertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical
    preferredRepresentation: compactRepresentation
    Plasmoid.backgroundHints: PlasmaCore.Types.ShadowBackground
    compactRepresentation: CompactRepresentation {}
    fullRepresentation: Item {}
    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: i18ndc("plasma_applet_org.kde.plasma.systemmonitor",
                         "@action", "Open System Monitor…")
            icon.name: "utilities-system-monitor"
            priority: Plasmoid.LowPriorityAction
            onTriggered: executable.exec("plasma-systemmonitor")
        }
    ]
    P5Support.DataSource {
        id: executable

        signal exited(string cmd, int exitCode, int exitStatus, string stdout, string stderr)

        function exec(cmd) {
            if (cmd)
                connectSource(cmd);

        }

        engine: "executable"
        connectedSources: []
        onNewData: function(sourceName, data) {
            const exitCode = data["exit code"];
            const exitStatus = data["exit status"];
            const stdout = data["stdout"];
            const stderr = data["stderr"];
            exited(sourceName, exitCode, exitStatus, stdout, stderr);
            disconnectSource(sourceName);
        }
    }
}
