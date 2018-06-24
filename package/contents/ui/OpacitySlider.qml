import QtQuick 2.4
import QtQuick.Layouts 1.1
import org.kde.plasma.components 2.0 as PlasmaComponents

RowLayout {
	id: opacitySliderItem

	property alias label: label
	property alias valueLabel: valueLabel
	
	property alias text: label.text
	property alias value: opacitySlider.value

	property var setValueFunc: function() {}

	PlasmaComponents.Label {
		id: label
		text: "Label:"
	}
	PlasmaComponents.Slider {
		id: opacitySlider
		minimumValue: 0
		maximumValue: 1
		stepSize: 0.01
		// value: main.widgetOpacity
		Layout.fillWidth: true
		Layout.fillHeight: true
		onValueChanged: {
			if (!(main.configLoaded && popupView.loaded)) return;

			// main.deferredSetWidgetOpacity(value)
			opacitySliderItem.setValueFunc(value)
		}
	}
	PlasmaComponents.Label {
		id: valueLabel
		function formatText(val) {
			return Math.round(val * 100) + '%'
		}
		text: formatText(opacitySlider.value)
		opacity: 0.6
		Layout.preferredWidth: widthMetrics.width

		TextMetrics {
			id: widthMetrics
			text: valueLabel.formatText(1)
			font: valueLabel.font
		}
	}
}
