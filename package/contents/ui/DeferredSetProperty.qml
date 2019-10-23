import QtQuick 2.0

Timer {
	id: deferredSetProperty
	interval: 1000
	onTriggered: apply()

	property string propPath
	property string mainPropKey

	function apply() {
		// console.log('deferredSetProperty', 'apply', propPath, main[mainPropKey])
		main.setThemeProperty(propPath, main[mainPropKey])
	}
	function set(val) {
		// console.log('deferredSetProperty', 'set', propPath, main[mainPropKey])
		main[mainPropKey] = val
		restart()
	}
}
