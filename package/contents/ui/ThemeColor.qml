import QtQuick 2.4

Item {
	id: themeColorItem
	property string mainPropKey
	property string scriptFilename

	Timer {
		id: deferredApplyThemeColor
		interval: 1000
		onTriggered: themeColorItem.applyColor()
	}

	function applyColor() {
		runThemeScript('python3 ' + scriptFilename + ' ' + toColorStr(main[mainPropKey]))
	}

	function deferredSetColor(color) {
		main[mainPropKey] = color
		deferredApplyThemeColor.restart()
	}

	function setColor(color) {
		main[mainPropKey] = color
		applyColor()
	}
}
