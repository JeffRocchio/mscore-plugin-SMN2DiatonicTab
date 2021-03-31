//=============================================================================
//  MuseScore - Build TAB from SMN staff 
//=============================================================================

import MuseScore 3.0

		 // For user interface panels.
import QtQuick 2.1
import QtQuick.Layouts 1.2
import QtQuick.Controls 1.0
import QtQuick.Dialogs 1.0

MuseScore {
    menuPath: "Plugins.MakeD-Tab"
    description: "Working to build dulcimer TAB generator"
    version: "0.0.1"

    pluginType: "dialog"
		id: mainDialog
		width: 370
		height: 260
		// Neither of these work --> Layout.alignment: Qt.AlignLeft
		//anchors.left: parent.left
    
    property variant black     : "#000000"
    property variant red       : "#ff0000"
    property variant green     : "#00ff00"
    property variant blue      : "#0000ff"

	
	//==== Add a rest to the score, using the current cursor position and duration.
	function addRest(cursor) {
		// Adding a rest to the score requires a little dance ...
		
		// ... first we add a placeholder note.
		cursor.addNote(0);
		
		// ... go back to the note we just added
		cursor.prev();
		
		// ... create a new rest with the same duration as the placeholder object
		var e = newElement(Element.REST);
		e.durationType = cursor.element.durationType;
		e.duration = cursor.element.duration;
		
		// ... add the rest to the score
		cursor.add(e);
		
		// ... advance the cursor, because cursor.add() doesn't. (unlike cursor.addNote(), which does).
		cursor.next();
	}
	
	
	//==== Clear selected portion of target staff
	function clearStaff(track) {
								// *** I copied this from ExpandChordSymbols.js,
								// *** This function needs to be fixed up for
								// *** use.
		var cursor = curScore.newCursor();
		cursor.track = track;
		cursor.rewind(Cursor.SCORE_START);
		while (cursor.segment) {
			if (cursor.element.type === Element.CHORD) {
				removeElement(cursor.element);
			}
			cursor.next();
		}
	}
	
	
	
	
	
	//==== Walk through input staff and write out the TAB staff
	function makeTAB (staffIN, staffOUT) {
								//   We have the input and output staves,
								//so now walk through the input and write
								//out the TAB.
		var endTick = 0;
		var INstaffix = 0;
		var notes;
		var numNotes = 0;
		
		console.log("Input Staff Passed In: ", staffIN);
		console.log("Output Staff Passed In: ", staffOUT);
		
		INstaffix = staffIN;
		
		var cursor = curScore.newCursor()
		cursor.staffIdx = INstaffix;
		
		// Get tick-number for end of the selection.
		cursor.rewind(2);
		if (cursor.tick === 0) {
			//   (This happens when the selection includes
			//the last measure of the score. rewind(2) goes 
			//behind the last segment (where there's none) 
			//and sets tick=0)
			endTick = curScore.lastSegment.tick + 1;
		} else {
			endTick = cursor.tick;
		}
		cursor.rewind(1) //  Move cursor back to start of selection.
		curScore.startCmd();
		while (cursor.segment && cursor.tick < endTick) {
			if (cursor.element.type === Element.CHORD) {
				notes = cursor.element.notes;
				numNotes = notes.length;

				//Let's try to just add a note on the std staff.
				cursor.staffIdx = staffIN;
				cursor.addNote (notes[0].pitch-3, true);

				//Now add note to TAB staff
				cursor.staffIdx = staffOUT;
				console.log("String Number: ", cursor.stringNumber);
				//console.log("Setting String Number to 101");
				//cursor.stringNumber = 101;
				//console.log("New String Number: ", cursor.stringNumber);
				console.log("Note to Write to TAB Staff: ", notes[0].pitch);
				cursor.addNote (notes[0].pitch, false);
			}
			cursor.staffIdx = staffIN;
			//cursor.next();  // <-- .addNote(pitch, false) will automatically advance cursor. But .addNote(ptich, true) will not.
		} // end while
		curScore.endCmd();


	} // END MakeTAB()
	
	
	
	
	
	onRun: { 
		var numberOfParts = curScore.parts.length;
		var numberOfStaves = curScore.nstaves;
		var staffDisplayName = "";
        var cursor = curScore.newCursor()
		var staffIN = 0;
		var staffOUT = 0;

		var numNotes = 0;
		var endTick = 0;
		var notes;
		var sText = newElement(Element.STAFF_TEXT);
        
		var thepartslist =""; //<-- for debug only.
		var theStavesList = ""; //<-- for debug only.


						// Determine if we have anything selected. If not, abort.
						//In this iteration I am requiring that the user make a
						//selection on the input staff.
		cursor.rewind(1)
		if (!cursor.segment) { 
						// no selection. Give a message then fall through to the
						//end, ending the plugin.
			console.log("No Selection. Select one, or all, measures on the input staff to TAB out.");

						//   Ok, we have something selected, 
						//so present user interface.
		} else {
			staffIN = cursor.staffIdx;
			inStaff.text = staffIN;
						// Get tick-number for end of the selection.
			cursor.rewind(2);
			if (cursor.tick === 0) {
						//   (This happens when the selection includes
						//the last measure of the score. rewind(2) goes 
						//behind the last segment (where there's none) 
						//and sets tick=0)
				endTick = curScore.lastSegment.tick + 1;
			} else {
				endTick = cursor.tick;
			}
			console.log("Selection Ends On Tick: ", endTick);

			//BUILD USER INTERFACE --	
			
			console.log("Number of Parts in Score: ", curScore.parts.length);
			console.log("Number of Staves in Score: ", numberOfStaves);
			console.log("Input Staff Detected: ", staffIN);

			if (numberOfParts > 0) {
												//   Populate combobox with the 
												//list of parts.
				for (var i = 0; i < curScore.parts.length; i++) {
					thepartslist += curScore.parts[i].partName + ", "; //<-- for debug only.
					partsList.model.append({text: curScore.parts[i].partName});
				}
				//For DUBUG 
				console.log("The Parts in Score: ", thepartslist);
			}
			if (numberOfStaves > 0) {
												//   Populate combobox with the 
												//list of staves.
				for (var i = 0; i < curScore.nstaves; i++) {
					theStavesList += i + ", "; //<-- for debug only.
					if (i == 0) { staffDisplayName = i + " : First Staff"; }
					else if (i == curScore.nstaves-1) { staffDisplayName = i + " : Last Staff"; }
					else { staffDisplayName = i + " "; }
					cursor.staffIdx = i; //Point to next staff;
					outputStaff.model.append({text: staffDisplayName});
				}
			}

			
		} // end top else stmt
		
		
	} // END onRun

   //=============================================================================
   //User Interface
   //=============================================================================

   GridLayout {
	  Layout.fillHeight: parent
	  anchors.top: mainDialog.top
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
				id: partsModel
			}
		}			

		Text {
			Layout.leftMargin: 10
			Layout.rightMargin: 10
			text: "Input Staff"
		}
		
		TextField {
			id: inStaff
			
		}
		
		
		Text {
			Layout.leftMargin: 10
			Layout.rightMargin: 10
			text: "Select TAB Staff to Write To"
			color: "black"
			}

		ComboBox {
			id: outputStaff
			model: ListModel {
				id: outputStaffModel
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
				makeTAB(parseInt(inStaff.text, 10), outputStaff.currentIndex)
				}
		}


} // End GridLayout
   

} // End Musescore
