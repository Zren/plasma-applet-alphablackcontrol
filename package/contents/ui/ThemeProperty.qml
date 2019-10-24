import QtQuick 2.0

Timer {
	id: themeProperty
	interval: 1000
	onTriggered: apply()

	property string propPath
	property string mainPropKey

	function getValue() {
		return main[mainPropKey]
	}
	function apply() {
		var value = getValue()
		// console.log('ThemeProperty', 'apply', propPath, value)
		set(value)
	}
	function set(val) {
		// console.log('ThemeProperty', 'set', propPath, val)
		main.setThemeProperty(propPath, val, callback)
	}
	function deferredSet(val) {
		// console.log('ThemeProperty', 'deferredSet', propPath, main[mainPropKey])
		main[mainPropKey] = val
		restart()
	}

	signal callback()
}
