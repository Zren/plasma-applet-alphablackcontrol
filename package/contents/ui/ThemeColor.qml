import QtQuick 2.4

ThemeProperty {
	id: themeProperty

	function getValue() {
		return toColorStr(main[mainPropKey])
	}
}
