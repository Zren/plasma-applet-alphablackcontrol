import QtQuick 2.0
import QtQuick.Controls 1.0
import QtQuick.Layouts 1.0

import ".."
import "../lib"

ConfigPage {
	id: page
	showAppletVersion: true

	ConfigSection {
		Label {
			text: i18n("Thanks for using the AlphaBlack theme.")
		}
	}
}
