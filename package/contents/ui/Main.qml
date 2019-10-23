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

	property bool validDesktopTheme: theme.themeName == 'breeze-alphablack' || theme.themeName == 'breeze-dark'
	property bool widgetsUnlocked: plasmoid.immutability === PlasmaCore.Types.Mutable
	Plasmoid.status: validDesktopTheme && widgetsUnlocked ? PlasmaCore.Types.ActiveStatus : PlasmaCore.Types.HiddenStatus

	property string taskStyle: 'inside'
	property color themeAccentColor: "#000000"
	property color themeHighlightColor: "#000000"
	property color themeTextColor: "#000000"
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


	//----
	function parseColorStr(str) {
		var tokens = str.split(',')
		var red = parseInt(tokens[0], 10) / 255
		var green = parseInt(tokens[1], 10) / 255
		var blue = parseInt(tokens[2], 10) / 255
		return Qt.rgba(red, green, blue, 1)
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


	//----
	function runThemeScript(relativeCommand, callback) {
		console.log('runThemeScript', relativeCommand)
		var cmd =  'cd ~/.local/share/plasma/desktoptheme/breeze-alphablack/ && ' + relativeCommand
		executable.exec(cmd, callback)
	}
	function runThemeCommand(command, callback) {
		var relativeCommand = 'python3 desktoptheme.py ' + command
		runThemeScript(relativeCommand, callback)
	}
	function getAllThemeProperties(callback) {
		var command = 'getall --json'
		runThemeCommand(command, function(cmd, exitCode, exitStatus, stdout, stderr) {
			// console.log(cmd, exitCode, exitStatus, stdout, stderr)
			var config = JSON.parse(stdout)
			callback(config)
		})
	}
	function getThemeProperty(propPath, callback) {
		var command = 'get ' + propPath
		runThemeCommand(command, function(cmd, exitCode, exitStatus, stdout, stderr) {
			// console.log(cmd, exitCode, exitStatus, stdout, stderr)
			var value = JSON.parse(stdout)
			callback(value)
		})
	}
	function setThemeProperty(propPath, value, callback) {
		var command = 'set ' + propPath + ' ' + value
		runThemeCommand(command, function(cmd, exitCode, exitStatus, stdout, stderr) {
			// console.log(cmd, exitCode, exitStatus, stdout, stderr)
			callback()
		})
	}

	//----
	property bool configLoaded: false
	function readConfig() {
		getAllThemeProperties(function(config) {
			// console.log('config', JSON.stringify(config, null, '\t'))
			main.configLoaded = false
			main.themeAccentColor = parseColorStr(config.theme.accentColor)
			main.themeHighlightColor = parseColorStr(config.theme.highlightColor)
			main.themeTextColor = parseColorStr(config.theme.textColor)
			main.dialogOpacity = config.dialog.opacity
			main.panelOpacity = config.panel.opacity
			main.widgetOpacity = config.widget.opacity
			main.taskStyle = config.panel.taskStyle
			main.configLoaded = true
			// console.log('main.themeAccentColor', main.themeAccentColor)
			// console.log('main.dialogOpacity', main.dialogOpacity)
			// console.log('main.panelOpacity', main.panelOpacity)

			// If we've modified any values, the binding has been broken, so rebind to the properties.
			if (main.Plasmoid.fullRepresentationItem) {
				main.Plasmoid.fullRepresentationItem.updateConfigBindings()
			}
		})
	}
	Component.onCompleted: readConfig()


	//----
	ThemeColor {
		id: accentColorItem
		mainPropKey: 'themeAccentColor'
		scriptFilename: 'setthemecolor.py'
	}

	ThemeColor {
		id: highlightColorItem
		mainPropKey: 'themeHighlightColor'
		scriptFilename: 'sethighlightcolor.py'
	}

	ThemeColor {
		id: textColorItem
		mainPropKey: 'themeTextColor'
		scriptFilename: 'settextcolor.py'
	}

	//----
	function resetAllToDefaults() {
		runThemeCommand('reset', function(cmd, exitCode, exitStatus, stdout, stderr) {
			main.readConfig()
		})
	}

	//----
	function applyTitleBarColors() {
		runThemeScript('python3 settitlebarcolor.py ' + toColorStr(themeAccentColor) + ' ' + toColorStr(themeTextColor))
	}

	function resetTitleBarColors() {
		runThemeCommand('resettitlebarcolors')
	}
	
	//----
	function setTaskSvg(taskStyle) {
		setThemeProperty('panel.taskStyle', taskStyle)
	}

	//----
	Timer {
		id: deferredApplyDialogOpacity
		interval: 1000
		onTriggered: main.applyDialogOpacity()
	}

	function applyDialogOpacity() {
		setThemeProperty('dialog.opacity', dialogOpacity)
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
		setThemeProperty('panel.opacity', panelOpacity)
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
		setThemeProperty('widget.opacity', widgetOpacity)
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

		function updateConfigBindings() {
			accentColorSelector.value = Qt.binding(function() { return main.themeAccentColor })
			textColorSelector.value = Qt.binding(function() { return main.themeTextColor })
			highlightColorSelector.value = Qt.binding(function() { return main.themeHighlightColor })
		}


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
				
				ColumnLayout {
					spacing: 0

					PlasmaExtras.Heading {
						text: i18n("Accent Color")
						level: 3
						lineHeight: 1
					}

					PlasmaComponents.Label {
						text: i18n("Panel, Widget, Window Titlebars & Frames")
						opacity: 0.6
					}
				}

				ConfigColor {
					id: accentColorSelector
					Layout.fillWidth: true
					value: main.themeAccentColor
					label: ""
					showAlphaChannel: false
					
					onValueChanged: apply()
					function apply() {
						if (!(main.configLoaded && popupView.loaded)) return;

						if (textField.text.charAt(0) === '#' && textField.text.length == 7) {
							accentColorItem.deferredSetColor(textField.text)
						}
					}
				}

				PlasmaComponents.Label {
					text: i18n("Text Color")
					opacity: 0.6
				}

				ConfigColor {
					id: textColorSelector
					Layout.fillWidth: true
					value: main.themeTextColor
					label: ""
					showAlphaChannel: false
					
					onValueChanged: apply()
					function apply() {
						if (!(main.configLoaded && popupView.loaded)) return;

						if (textField.text.charAt(0) === '#' && textField.text.length == 7) {
							textColorItem.deferredSetColor(textField.text)
						}
					}
				}

				PlasmaComponents.Label {
					text: i18n("Highlight Color")
					opacity: 0.6
				}

				ConfigColor {
					id: highlightColorSelector
					Layout.fillWidth: true
					value: main.themeHighlightColor
					label: ""
					showAlphaChannel: false
					
					onValueChanged: apply()
					function apply() {
						if (!(main.configLoaded && popupView.loaded)) return;

						if (textField.text.charAt(0) === '#' && textField.text.length == 7) {
							highlightColorItem.deferredSetColor(textField.text)
						}
					}
				}

				ColumnLayout {
					spacing: 0

					PlasmaExtras.Heading {
						text: i18n("Window Titlebars & Frames")
						level: 3
						lineHeight: 1
					}

					PlasmaComponents.Label {
						Layout.fillWidth: true
						text: i18n("Apply accent color to Breeze window decorations?")
						opacity: 0.6
						wrapMode: Text.Wrap
					}
				}
				
				RowLayout {
					PlasmaComponents.Button {
						text: i18n("Apply Colors")
						iconName: "dialog-ok-apply"
						onClicked: main.applyTitleBarColors()
						implicitWidth: minimumWidth
					}
					PlasmaComponents.Button {
						text: i18n("Reset Colors")
						iconName: "edit-undo-symbolic"
						onClicked: main.resetTitleBarColors()
						implicitWidth: minimumWidth
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

				Item {
					Layout.preferredHeight: units.largeSpacing
				}

				RowLayout {
					PlasmaCore.IconItem {
						source: "unlock"
						Layout.preferredWidth: units.iconSizes.medium
						Layout.preferredHeight: units.iconSizes.medium
						Layout.alignment: Qt.AlignTop
					}

					PlasmaComponents.Label {
						Layout.fillWidth: true
						text: i18n("Lock Widgets to hide the AlphaBlack Control widget, or uninstall the widget via \"Add Widgets\".")
						opacity: 0.6
						wrapMode: Text.Wrap
					}
				}

				Item {
					Layout.preferredHeight: units.largeSpacing
				}

				PlasmaComponents.Button {
					text: i18n("Reset To Defaults")
					iconName: "edit-undo-symbolic"
					onClicked: main.resetAllToDefaults()
					implicitWidth: minimumWidth
					Layout.alignment: Qt.AlignHCenter
				}

			}
		}
	}
}
