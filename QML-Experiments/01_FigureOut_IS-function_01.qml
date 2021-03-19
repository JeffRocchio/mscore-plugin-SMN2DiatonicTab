//=============================================================================
//  MuseScore
//  Music Composition & Notation
//
//=============================================================================

import QtQuick 2.2
import QtQuick.Layouts 1.2
import QtQuick.Controls 1.0
import QtQuick.Dialogs 1.1
import MuseScore 3.0

MuseScore {
	version: "1.0.0"
	description: qsTr("Figure Out IS() Function")
	menuPath: "Plugins.DEV - Ties"

	
	onRun: {
		
		var oCursor = curScore.newCursor();
		var iSMNIdx = 0; 
		var iTABIdx = 1;
		var iTkOrigin = 0;
		var iTkBackNote = 0;
		
		var iPitchToMatch =62;
		
		var oBackSMNnote;
		var oOriginTABchord;
		var oBackChord;
		var oBackTABnote;
		var oTie;
		

		oCursor.staffIdx = iSMNIdx;
		oCursor.rewind(Cursor.SCORE_START);
		
					//	Set a boundary for the while() loop.
					//	I just want to process the 1st measure. 
					//(A measure's lastSegment is the measure-ending barline, 
					//and I don't want to pass through the while() loop 
					//attempting to process the barline; although I don't 
					//think doing that would actually hurt anything.)
		var iLastTick = oCursor.measure.lastSegment.tick - 1;
		console.log("\n\niLastTick <", iLastTick, "> (last segment in measure is a ", oCursor.measure.lastSegment.type, ")");
		
		console.log("\n *** Ready to run the experiment ***\n");
		
		var oNote1 = null;
		var oNote2 = null;
		var oNote3 = null;
		var oNote4 = null;
		var bResult = false;
					//	Set an infinite-loop watchdog
		var iWatchDog = 0;
		while (oCursor.segment && oCursor.tick < iLastTick+1) {
			console.log("\nTOP of While Loop, cursor at tick <", oCursor.tick, "> \n");
			if(oCursor.element.type === Element.CHORD) {
				iTkOrigin = oCursor.tick;

				console.log("\n------------------------------ | CHORD at Tick ", iTkOrigin," | ------------------------------");
				console.log("---- SMN Chord Contains <", oCursor.element.notes.length,"> Notes\n");
				console.log("---- SMN Chord's Note[0] pitch <", oCursor.element.notes[0].pitch,"> \n");
				
					//	Make an is() test come out false |<-- this does come out false.
				console.log("\n---- Experiment One, Try for a FALSE Result");
				if (oNote1 == null) {
					oNote1 = oCursor.element.notes[0];
					console.log("---- ---- oNote1 pitch <", oNote1.pitch,"> ");
				} else {
					oNote2 = oCursor.element.notes[0];
					console.log("---- ---- oNote1 pitch <", oNote2.pitch,"> ");
				}
				//bResult = curScore.is(oNote1, oNote2);
				bResult = oNote1.is(oNote2);
				console.log("---- ---- Result of is() call is <", bResult,">");

					//	Make an is() test come out true |<-- this does come out TRUE.
				console.log("\n---- Experiment Two, Try for a TRUE Result");
				oNote3 = oCursor.element.notes[0];
				oNote4 = oCursor.element.notes[0];
				console.log("---- ---- oNote3 pitch <", oNote3.pitch,"> ");
				bResult = oNote3.is(oNote4);
				console.log("---- ---- Result of is() call is <", bResult,"> ");
				
			} // end the chord-sensing IF()
			oCursor.next();
			iWatchDog++
			if(iWatchDog > 10) {
				console.log("***** BREAKING OUT FROM INFINITE LOOP ******");
				break;
			} // end watchdog test if() stmt
		} //end the big walk-through-the-score while()

	console.log("\n--- Plugin Exiting ---");
	Qt.quit();
	} // end onRun

	
	
	//==== PLUGIN USER INTERFACE OBJECTS ===========================================
	
	MessageDialog {
		id: pauseDialog
		visible: false
		title: qsTr("Pause to Inspect")
		text: "Pause to Inspect"
		onAccepted: {
			Qt.quit()
		}
		function openPauseDialog(message) {
			text = message
			open()
		}
	}

	
}
