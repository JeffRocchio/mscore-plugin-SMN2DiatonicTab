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
	description: qsTr("Figure out how to write ties given my arrTies list")
	menuPath: "Plugins.DEV - Ties"

// Meant to run against score: REFcode_Ties_tie-tests-v6.mscz
// NOTE: This does work.
	
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
		
		var arrTies = [];
		

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
	
		var first_NoteTick = null;
		var first_oSMNnote = null;
		var first_oTABnote = null;
		var first_oTie = null;
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
				
					//	Walk the chord's notes looking for ties
				for(var i=0; i<oCursor.element.notes.length; i++) {
					if(oCursor.element.notes[i].tieForward != null) {
						first_NoteTick = oCursor.tick;
						first_oSMNnote = oCursor.element.notes[i];
						first_oTie = oCursor.element.notes[i].tieForward;
						oCursor.staffIdx = iTABIdx;
						if(oCursor.element.notes[i] != null) first_oTABnote = oCursor.element.notes[i];
						oCursor.staffIdx = iSMNIdx;
						arrTies.push({ // <-- See CD-10 Key Learning for why this must be done using indiv variables vs an object. And also why 'push' vs 'unshift'
						 	"first_NoteTick": first_NoteTick,
						 	"first_oSMNnote": first_oSMNnote,
							"first_oTABnote": first_oTABnote,
							"first_oTie": first_oTie
					})
					}
				}
				console.log("\n---- Array Listing -->>");
				console.log("---- ---- array size <",arrTies.length, ">");
				for(var i=0; i<arrTies.length; i++) {
					console.log("---- ---- Note <", i, ">");
					console.log("---- ---- ---- oSMNNote's Tick <", arrTies[i].first_NoteTick, ">");
					console.log("---- ---- ---- oSMNNote's Pitch <", arrTies[i].first_oSMNnote.pitch, ">");
					console.log("---- ---- ---- oTABnote's Pitch <", arrTies[i].first_oTABnote.pitch, ">");
					console.log("---- ---- ---- End Note's Tick <", arrTies[i].first_oTie.endNote.parent.parent.tick, ">\n");
				}
				
					//	Now let's pretend we are in TAB chord writing mode.
					//Can we sense a back-tie that matches an item in the arrTies list?
					//And if so, can we apply the tie to the proper TAB notes.
					//And lastly, can we remove the completed item from arrTies list
					//without breaking anything?
					//	Before entering the below loop we would have written out the TAB notes.
					//So now we are going into the below loop to process any pending ties
					//that terminate at this cursor tick.
					console.log("");
					console.log("Processing Tie List -->>");
					//curScore.startCmd(); // <-- sadly, these don't work to create a single undo block in this case.
					for(var i=0; i<arrTies.length; i++) {
						if(arrTies[i].first_oTie.endNote.parent.parent.tick == oCursor.tick) {
							console.log("---- Found a match, making a tie on TAB staff -->>");
							curScore.selection.select(arrTies[i].first_oTABnote, false);
							cmd("tie");
						}
						console.log("");
					} // End loop where we are pretenting to process pending ties at current cursor location.
					//curScore.endCmd();
				
				
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
