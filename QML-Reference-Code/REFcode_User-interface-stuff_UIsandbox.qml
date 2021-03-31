//=============================================================================
//  MuseScore - Trying to learn how to build a User Interface for a plugin 
//=============================================================================

import MuseScore 3.0

		 // For user interface panels.
import QtQuick 2.1
import QtQuick.Layouts 1.2
import QtQuick.Controls 1.0
import QtQuick.Dialogs 1.0

MuseScore {
    menuPath: "Plugins.UIsandbox"
    description: "Learning to build a user interface."
    version: "0.0.1"

    pluginType: "dialog"
		id: testDialog
		width: 370
		height: 260
		// Neither of these work --> Layout.alignment: Qt.AlignLeft
		//anchors.left: parent.left
    
    property variant black : "#000000"
    property variant red       : "#ff0000"
    property variant green     : "#00ff00"
    property variant blue      : "#0000ff"

	onRun: { 
		var numberOfParts = curScore.parts.length;
		var numberOfStaves = curScore.nstaves;
		var thepartslist =""; //<-- for debug only.
        var cursor = curScore.newCursor()

		
		console.log("Number of Parts in Score: ", curScore.parts.length);
		if (numberOfParts > 0) {
											//   Populate combobox with the 
											//list of parts.
			for (var i = 0; i < curScore.parts.length; i++) {
				thepartslist += curScore.parts[i].partName + ", "; //<-- for debug only.
				partsList.model.append({text: curScore.parts[i].partName});
			}
			//For DUBUG 
			console.log(thepartslist);
			console.log("Num of Staves:", numberOfStaves);
		}
		if (numberOfStaves > 0) {
											//   Populate combobox with the 
											//list of staves.
			cursor.rewind(0); // beginning of score
			for (var i = 0; i < curScore.nstaves; i++) {
		        cursor.staffIdx = i; //Point to next staff;
				

				inputStaff.model.append({text: curScore.parts[i].partName});
			}
		}

		
		
	}

   //=============================================================================
   //User Interface
   //=============================================================================

   GridLayout {
	  Layout.fillHeight: parent
	  anchors.top: testDialog.top
	  anchors.topMargin: 10
	  anchors.horizontalCenter: parent.horizontalCenter
	  // Has no effect, don't know why --> anchors.verticalCenter: parent.verticleCenter
	  columns: 2
	  rowSpacing: 5

		Text {
			Layout.leftMargin: 10
			Layout.rightMargin: 10
			text: "Parts in Score"
			}

		ComboBox {
			id: partsList
			Layout.fillWidth: true
			model: ListModel {
				id: partsfModel
			}
		}			
			
		Text {
			Layout.leftMargin: 10
			Layout.rightMargin: 10
			text: "Select Input Staff"
			color: "black"
			}

		ComboBox {
			id: inputStaff
			model: ListModel {
				id: inputStaffModel
			}
		}			
			
		Text {
											//   Used to create a blank row
											//between the input controls and
											//and the action buttons.
			Layout.leftMargin: 10
			Layout.rightMargin: 10
			Layout.columnSpan: 2
			text: "   "
			color: "black"
		}

		Button {
			id: buttonCancel
			Layout.leftMargin: 10
			Layout.rightMargin: 10
			Layout.fillWidth: true
			// Has no effect, don't know why --> Layout.row: 4
			// Doesn't do anything --> Layout.rowSpan: 2
			text: qsTr("Cancel")
			onClicked: {
			Qt.quit();
			}
		}

		Button {
			id: buttonCreate
			Layout.leftMargin: 10
			Layout.rightMargin: 10
			Layout.fillWidth: true
			// Has no effect, don't know why --> Layout.row: 4
			//Layout.rowSpan: 2
			text: "create"
			onClicked: {
				//createScore()
				}
		}


} // End GridLayout
   

} // End Musescore
