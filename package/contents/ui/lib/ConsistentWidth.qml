import QtQuick 2.0
import QtQuick.Layouts 1.0 // Needed to access item.Layout.minimumWidth

QtObject {
	id: consistentWidth
	property var items: []
	property real maxWidth: 0

	// TODO: Ingore items we've already connected.
	// TODO: Disconnect listeners when removed.
	onItemsChanged: {
		applyBindings()
		onItemWidthChanged()
	}

	function applyBindings() {
		for (var i = 0; i < items.length; i++) {
			var item = items[i]
			item.implicitWidthChanged.connect(consistentWidth.onItemWidthChanged)
			item.Layout.minimumWidth = Qt.binding(function(){ return consistentWidth.maxWidth })
		}
	}

	function onItemWidthChanged() {
		// console.log('onItemWidthChanged')
		if (items.length >= 1) {
			var newMaxWidth = items[0].implicitWidth
			for (var i = 1; i < items.length; i++) {
				var item = items[i]
				if (item.implicitWidth > newMaxWidth) {
					newMaxWidth = item.implicitWidth
				}
			}
			if (maxWidth != newMaxWidth) {
				// console.log('\tmaxWidth', maxWidth, '=>', newMaxWidth)
				maxWidth = newMaxWidth
			}
		}
	}
}
