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

	property string targetDesktopTheme: 'breeze-alphablack'

	property bool validDesktopTheme: theme.themeName == targetDesktopTheme || theme.themeName == 'breeze-dark'
	property bool widgetsUnlocked: plasmoid.immutability === PlasmaCore.Types.Mutable
	Plasmoid.status: validDesktopTheme && widgetsUnlocked ? PlasmaCore.Types.ActiveStatus : PlasmaCore.Types.HiddenStatus

	property string taskStyle: 'inside'
	property color themeAccentColor: "#000000"
	property color themeHighlightColor: "#000000"
	property color themeTextColor: "#000000"
	property real dialogOpacity: 0.9
	property real panelOpacity: 0.9
	property real widgetOpacity: 0.9
	property int dialogPadding: 6
	property int panelPadding: 2

	ExecUtil {
		id: executable
	}

	KCoreAddons.KUser {
		id: kuser
	}

	readonly property string breezeAlphaBlackDir: {
		if (kuser.loginName) {
			return '/home/' + kuser.loginName + '/.local/share/plasma/desktoptheme/' + targetDesktopTheme
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
		// console.log('runThemeScript', relativeCommand)
		var cmd =  'cd ~/.local/share/plasma/desktoptheme/' + targetDesktopTheme + '/ && ' + relativeCommand
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
			callback && callback(config)
		})
	}
	function getThemeProperty(propPath, callback) {
		var command = 'get ' + propPath
		runThemeCommand(command, function(cmd, exitCode, exitStatus, stdout, stderr) {
			// console.log(cmd, exitCode, exitStatus, stdout, stderr)
			var value = JSON.parse(stdout)
			callback && callback(value)
		})
	}
	function setThemeProperty(propPath, value, callback) {
		var command = 'set ' + propPath + ' ' + value
		runThemeCommand(command, function(cmd, exitCode, exitStatus, stdout, stderr) {
			// console.log(cmd, exitCode, exitStatus, stdout, stderr)
			callback && callback()
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
			main.dialogPadding = config.dialog.padding
			main.panelPadding = config.panel.padding
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
		id: accentColorProperty
		propPath: 'theme.accentColor'
		mainPropKey: 'themeAccentColor'
	}

	ThemeColor {
		id: highlightColorProperty
		propPath: 'theme.highlightColor'
		mainPropKey: 'themeHighlightColor'
	}

	ThemeColor {
		id: textColorProperty
		propPath: 'theme.textColor'
		mainPropKey: 'themeTextColor'
	}

	//----
	function resetAllToDefaults() {
		runThemeCommand('reset', function(cmd, exitCode, exitStatus, stdout, stderr) {
			main.readConfig()
		})
	}

	//----
	function applyTitleBarColors() {
		runThemeCommand('settitlebarcolors ' + toColorStr(themeAccentColor) + ' ' + toColorStr(themeTextColor))
	}

	function resetTitleBarColors() {
		runThemeCommand('resettitlebarcolors')
	}
	
	//----
	function setTaskSvg(taskStyle) {
		setThemeProperty('panel.taskStyle', taskStyle)
	}

	//----
	ThemeProperty {
		id: dialogOpacityProperty
		propPath: 'dialog.opacity'
		mainPropKey: 'dialogOpacity'
	}
	ThemeProperty {
		id: panelOpacityProperty
		propPath: 'panel.opacity'
		mainPropKey: 'panelOpacity'
	}
	ThemeProperty {
		id: widgetOpacityProperty
		propPath: 'widget.opacity'
		mainPropKey: 'widgetOpacity'
	}

	//----
	ThemeProperty {
		id: dialogPaddingProperty
		propPath: 'dialog.padding'
		mainPropKey: 'dialogPadding'

		onCallback: {
			plasmoid.expanded = false
		}
	}
	ThemeProperty {
		id: panelPaddingProperty
		propPath: 'panel.padding'
		mainPropKey: 'panelPadding'
	}


	//----
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
					buttonOutlineColor: theme.textColor
					
					onValueChanged: apply()
					function apply() {
						if (!(main.configLoaded && popupView.loaded)) return;

						if (textField.text.charAt(0) === '#' && textField.text.length == 7) {
							accentColorProperty.deferredSet(textField.text)
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
					buttonOutlineColor: theme.textColor
					
					onValueChanged: apply()
					function apply() {
						if (!(main.configLoaded && popupView.loaded)) return;

						if (textField.text.charAt(0) === '#' && textField.text.length == 7) {
							textColorProperty.deferredSet(textField.text)
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
					buttonOutlineColor: theme.textColor
					
					onValueChanged: apply()
					function apply() {
						if (!(main.configLoaded && popupView.loaded)) return;

						if (textField.text.charAt(0) === '#' && textField.text.length == 7) {
							highlightColorProperty.deferredSet(textField.text)
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
					setValueFunc: dialogOpacityProperty.deferredSet
				}

				OpacitySlider {
					id: panelOpacitySlider
					text: i18n("Panel:")
					value: main.panelOpacity
					setValueFunc: panelOpacityProperty.deferredSet
				}

				OpacitySlider {
					id: widgetOpacitySlider
					text: i18n("Desktop\nWidgets:")
					value: main.widgetOpacity
					setValueFunc: widgetOpacityProperty.deferredSet
				}

				PlasmaExtras.Heading {
					text: i18n("Padding")
					level: 3
				}

				OpacitySlider {
					id: dialogPaddingSlider
					text: i18n("Popup:")
					value: main.dialogPadding
					setValueFunc: dialogPaddingProperty.deferredSet
					minimumValue: 0
					maximumValue: 40
					stepSize: 1

					function formatValue(val) {
						return i18n("%1pt", val)
					}
				}

				OpacitySlider {
					id: panelPaddingSlider
					text: i18n("Panel:")
					value: main.panelPadding
					setValueFunc: panelPaddingProperty.deferredSet
					minimumValue: 0
					maximumValue: 40
					stepSize: 1

					function formatValue(val) {
						return i18n("%1pt", val)
					}
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
