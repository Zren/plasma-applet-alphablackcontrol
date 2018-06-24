import QtQuick 2.4
import QtQuick.Controls 1.0
import QtQuick.Layouts 1.1
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.kcoreaddons 1.0 as KCoreAddons

import "lib"

Item {
	id: main

	property bool widgetsUnlocked: plasmoid.immutability === PlasmaCore.Types.Mutable
	Plasmoid.status: widgetsUnlocked ? PlasmaCore.Types.ActiveStatus : PlasmaCore.Types.PassiveStatus

	property string taskStyle: 'inside'
	property color themeAccentColor: "#000000"
	property real dialogOpacity: 0.9
	property real panelOpacity: 0.9
	property real widgetOpacity: 0.9

	ExecUtil {
		id: executable
	}

	KCoreAddons.KUser {
		id: kuser
	}

	readonly property string breezeAlphaBlackDir: {
		if (kuser.loginName) {
			return '/home/' + kuser.loginName + '/.local/share/plasma/desktoptheme/breeze-alphablack'
		} else {
			return ''
		}
	}

	function toRGB(color) {
		return {
			'red': parseInt(color.toString().substr(1, 2), 16),
			'green': parseInt(color.toString().substr(3, 2), 16),
			'blue': parseInt(color.toString().substr(5, 2), 16),
		};
	}

	function toColorStr(color) {
		var rgb = toRGB(color);
		return rgb.red + ',' + rgb.green + ',' + rgb.blue
	}

	function runThemeScript(relativeCommand, callback) {
		var cmd =  'cd ~/.local/share/plasma/desktoptheme/breeze-alphablack/ && ' + relativeCommand
		executable.exec(cmd, callback)
	}

	//----
	property bool configLoaded: false
	function readConfig() {
		runThemeScript('python3 readconfig.py', function(cmd, exitCode, exitStatus, stdout, stderr) {
			// console.log(cmd, exitCode, exitStatus, stdout, stderr)
			var config = JSON.parse(stdout)
			var accent = config.theme.accentColor.split(',')
			var accentRed = parseInt(accent[0], 10) / 255
			var accentGreen = parseInt(accent[1], 10) / 255
			var accentBlue = parseInt(accent[2], 10) / 255
			main.themeAccentColor = Qt.rgba(accentRed, accentGreen, accentBlue, 1)
			main.dialogOpacity = config.dialog.opacity
			main.panelOpacity = config.panel.opacity
			main.widgetOpacity = config.widget.opacity
			main.taskStyle = config.panel.taskStyle
			main.configLoaded = true
			// console.log('main.themeAccentColor', main.themeAccentColor)
			// console.log('main.dialogOpacity', main.dialogOpacity)
			// console.log('main.panelOpacity', main.panelOpacity)
		})
	}
	Component.onCompleted: readConfig()


	//----
	Timer {
		id: deferredApplyThemeColor
		interval: 1000
		onTriggered: main.applyThemeColor()
	}

	function applyThemeColor() {
		runThemeScript('python3 setthemecolor.py ' + toColorStr(themeAccentColor))
	}

	function deferredSetThemeColor(color) {
		themeAccentColor = color
		deferredApplyThemeColor.restart()
	}

	function setThemeColor(color) {
		themeAccentColor = color
		applyThemeColor()
	}
	
	//----
	function setTaskSvg(taskStyle) {
		runThemeScript('python3 settasksvg.py ' + taskStyle)
	}

	//----
	Timer {
		id: deferredApplyDialogOpacity
		interval: 1000
		onTriggered: main.applyDialogOpacity()
	}

	function applyDialogOpacity() {
		runThemeScript('python3 setdialogopacity.py ' + dialogOpacity)
	}

	function deferredSetDialogOpacity(val) {
		dialogOpacity = val
		deferredApplyDialogOpacity.restart()
	}

	//----
	Timer {
		id: deferredApplyPanelOpacity
		interval: 1000
		onTriggered: main.applyPanelOpacity()
	}

	function applyPanelOpacity() {
		runThemeScript('python3 setpanelopacity.py ' + panelOpacity)
	}

	function deferredSetPanelOpacity(val) {
		panelOpacity = val
		deferredApplyPanelOpacity.restart()
	}

	//----
	Timer {
		id: deferredApplyWidgetOpacity
		interval: 1000
		onTriggered: main.applyWidgetOpacity()
	}

	function applyWidgetOpacity() {
		runThemeScript('python3 setwidgetopacity.py ' + widgetOpacity)
	}

	function deferredSetWidgetOpacity(val) {
		widgetOpacity = val
		deferredApplyWidgetOpacity.restart()
	}


	Plasmoid.fullRepresentation: Item {
		id: popupView
		property bool loaded: false
		Component.onCompleted: loaded = true

		Layout.minimumWidth: units.gridUnit * 1
		Layout.minimumHeight: units.gridUnit * 1
		Layout.preferredWidth: units.gridUnit * 16
		Layout.preferredHeight: scrollView.contentHeight
		// Layout.maximumWidth: plasmoid.screenGeometry.width
		// Layout.maximumHeight: plasmoid.screenGeometry.height


		PlasmaExtras.ScrollArea {
			id: scrollView
			anchors.fill: parent
			readonly property int contentWidth: contentItem ? contentItem.width : width
			readonly property int contentHeight: contentItem ? contentItem.height : 0 // Warning: Binding loop
			readonly property int viewportWidth: viewport ? viewport.width : width
			readonly property int viewportHeight: viewport ? viewport.height : height

			ColumnLayout {
				width: scrollView.viewportWidth
				// width: parent.width
				PlasmaExtras.Heading {
					text: i18n("Accent Color")
					level: 3
				}

				PlasmaComponents.Label {
					text: i18n("Panel, Window Titlebars & Frames")
					opacity: 0.6
				}

				ConfigColor {
					Layout.fillWidth: true
					value: main.themeAccentColor
					label: ""
					showAlphaChannel: false
					onValueChanged: {
						if (!(main.configLoaded && popupView.loaded)) return;

						if (textField.text.charAt(0) === '#' && textField.text.length == 7) {
							main.deferredSetThemeColor(textField.text)
						}
					}
				}

				PlasmaExtras.Heading {
					text: i18n("Opacity")
					level: 3
				}

				ConsistentWidth {
					items: [
						dialogOpacitySlider.label,
						panelOpacitySlider.label,
						widgetOpacitySlider.label,
					]
				}

				OpacitySlider {
					id: dialogOpacitySlider
					text: i18n("Popups:")
					value: main.dialogOpacity
					setValueFunc: main.deferredSetDialogOpacity
				}

				OpacitySlider {
					id: panelOpacitySlider
					text: i18n("Panel:")
					value: main.panelOpacity
					setValueFunc: main.deferredSetPanelOpacity
				}

				OpacitySlider {
					id: widgetOpacitySlider
					text: i18n("Desktop\nWidgets:")
					value: main.widgetOpacity
					setValueFunc: main.deferredSetWidgetOpacity
				}

				PlasmaExtras.Heading {
					text: i18n("Taskbar")
					level: 3
				}

				RowLayout {
					Layout.fillWidth: true
					PlasmaComponents.RadioButton {
						id: frameInsideButton
						exclusiveGroup: ExclusiveGroup { id: frameGroup }
						checked: main.taskStyle == 'inside'
						onCheckedChanged: {
							if (!(main.configLoaded && popupView.loaded)) return;
							if (checked) {
								main.setTaskSvg("inside")
							}
						}
					}
					TaskPreview {
						id: frameInside
						Layout.fillWidth: true
						Layout.fillHeight: true
						imagePath: main.breezeAlphaBlackDir + '/_templates/tasks-inside.svg'
						label: i18n("Inside (Breeze)")
						onClicked: frameInsideButton.checked = true
					}
				}
				RowLayout {
					Layout.fillWidth: true
					PlasmaComponents.RadioButton {
						id: frameOutsideButton
						exclusiveGroup: frameGroup
						checked: main.taskStyle == 'outside'
						onCheckedChanged: {
							if (!(main.configLoaded && popupView.loaded)) return;
							if (checked) {
								main.setTaskSvg("outside")
							}
						}
					}
					TaskPreview {
						id: frameOutside
						Layout.fillWidth: true
						Layout.fillHeight: true
						
						imagePath: main.breezeAlphaBlackDir + '/_templates/tasks-outside.svg'
						label: i18n("Outside (Windows 10)")
						onClicked: frameOutsideButton.checked = true
					}
				}



			}
		}
	}
}
