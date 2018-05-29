// /usr/share/plasma/plasmoids/org.kde.plasma.taskmanager/contents/ui/Task.qml
import QtQuick 2.0
import QtQuick.Layouts 1.1
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents

MouseArea {
	id: task
	hoverEnabled: true


	property alias imagePath: frame.imagePath
	property alias prefix: frame.prefix
	property alias icon: icon.source
	property alias label: label.text

	PlasmaCore.FrameSvgItem {
		id: frame
		imagePath: "widgets/tasks"
		prefix: task.containsMouse ? "hover" : "normal"
		anchors.fill: parent

		RowLayout {
			id: iconBox
			anchors.fill: parent

			PlasmaCore.IconItem {
				id: icon
				Layout.fillHeight: true
				Layout.preferredWidth: height

				active: task.containsMouse
				enabled: true
				usesPlasmaTheme: false

				source: "xorg"
			}
			PlasmaComponents.Label {
				id: label
				Layout.fillWidth: true
				Layout.fillHeight: true
				text: i18n("App")
			}
		}
	}
}
