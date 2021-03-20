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
	description: qsTr("Put it all together to sense/create ties on TAB")
	menuPath: "Plugins.DEV - Ties"

// Meant to run against score: REFcode_Ties_tie-tests-v6.mscz
// NOTE: This works.
	
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
		
		var iLastTick = curScore.lastSegment.tick -1; //<-- We are walking the entire score.
		//var iLastTick = oCursor.measure.lastSegment.tick - 1;
		console.log("\n\niLastTick <", iLastTick, "> (last segment in score is a ", curScore.lastSegment.type, ")");
		
		console.log("\n *** Ready to run the experiment ***\n");

					//	See CD-10, Key Learning-2, for why we must use individual
					//intermediate variables for the elements we're going to store
					//in arrTies[] vs using a multi-property object as an
					//intermediate.
		var first_NoteTick = null;
		var first_oSMNnote = null;
		var first_oTABnote = null;
		var first_oTie = null;
		var last_NoteTick = null;
		var bResult = false;
		
					//	Walk through the score looking for ties on SMN staff,
					//building the arrTies[] list as we find them, and 
					//using the list to make ties on the TAB staff as we
					//find the matching 'lastNote.' And don't forget to remove
					//the completed tie element from the arrTies[] list.
		var iWatchDog = 0; // <-- Set an infinite-loop watchdog
		while (oCursor.segment && oCursor.tick < iLastTick+1) {
			//console.log("TOP of While Loop, cursor at tick <", oCursor.tick, "> \n");
			if(oCursor.element.type === Element.CHORD) {
				iTkOrigin = oCursor.tick;

				console.log("\n----------------------------------- | CHORD at Tick ", iTkOrigin," | -----------------------------------");
				console.log("---- SMN Chord Contains <", oCursor.element.notes.length,"> Notes, the Note[0] pitch is <", oCursor.element.notes[0].pitch,">");
				
					//	Walk the chord's notes looking for ties
				for(var i=0; i<oCursor.element.notes.length; i++) {
					if(oCursor.element.notes[i].tieForward != null) {
						first_NoteTick = oCursor.tick;
						first_oSMNnote = oCursor.element.notes[i];
						first_oTie = oCursor.element.notes[i].tieForward;
						last_NoteTick = first_oTie.endNote.parent.parent.tick;
						oCursor.staffIdx = iTABIdx;
						if(oCursor.element.notes[i] != null) first_oTABnote = oCursor.element.notes[i];
						oCursor.staffIdx = iSMNIdx;
						arrTies.push({ // <-- See CD-10 Key Learning for why this must be done in this syntax, and why 'push' must be used.
						 	first_NoteTick: first_NoteTick, 
							last_NoteTick: last_NoteTick, 
						 	first_oSMNnote: first_oSMNnote, 
							first_oTABnote: first_oTABnote, 
							first_oTie: first_oTie
							})
					}
				} // bottom of the for() loop where we are processing the chord's notes
				
/*				console.log("\n---- Array Listing BEFORE sorting -->>");
				console.log("---- ---- array size <",arrTies.length, ">");
				for(var i=0; i<arrTies.length; i++) {
					console.log("---- ---- Note <", i, ">");
					console.log("---- ---- ---- oSMNNote's Tick <", arrTies[i].first_NoteTick, ">");
					console.log("---- ---- ---- oSMNNote's Pitch <", arrTies[i].first_oSMNnote.pitch, ">");
					console.log("---- ---- ---- oTABnote's Pitch <", arrTies[i].first_oTABnote.pitch, ">");
					console.log("---- ---- ---- End Note's Tick <", arrTies[i].last_NoteTick, ">\n");
				}
*/
				
					
			} // end the chord-sensing IF()

					//	Now let's pretend we are in TAB chord writing mode. That is,
					//before this point we are in SMN staff reading mode; where we are
					//building the oChordInfo object data; and sensing ties to add
					//elements to arrTies[] as appropriate. So we are pretenting that
					//we have completed that process at the current cursor location, we
					//have all that data, and now entering a Tie-Writing procedure.
					//	So - can we sense a back-tie that matches an item in the arrTies list?
					//And if so, can we apply the tie to the proper TAB notes.
					//And lastly, can we remove the completed item from arrTies list
					//without breaking anything?
					//	Before entering the below loop we would have written out the TAB notes.
					//So now we are going into the below loop to process any pending ties
					//that terminate at this cursor tick.
			console.log("");
			console.log(" ====| Processing Tie List for Cursor Tick <", oCursor.tick, "> |====");
					
					//	Sort arrTies[] in prep for making use of it.
			function compare(a, b) {
				//console.log("*** In Function compare() *** | a <", a.last_NoteTick, "> b <", b.last_NoteTick, ">");
				return -1 * (a.last_NoteTick - b.last_NoteTick); // <- reverse order as I am pushing/popping from bottom of list.
			}
			arrTies.sort(compare);
			console.log("\n---- Array Listing After Sorting on last_NoteTick -->>");
			console.log("---- ---- array size <",arrTies.length, ">");
			for(var i=0; i<arrTies.length; i++) {
				console.log("---- ---- Note <", i, ">");
				console.log("---- ---- ---- oSMNNote's Tick <", arrTies[i].first_NoteTick, ">");
				console.log("---- ---- ---- oSMNNote's Pitch <", arrTies[i].first_oSMNnote.pitch, ">");
				console.log("---- ---- ---- oTABnote's Pitch <", arrTies[i].first_oTABnote.pitch, ">");
				console.log("---- ---- ---- End Note's Tick <", arrTies[i].last_NoteTick, ">\n");
			}
			
			console.log("");
			while((arrTies.length > 0) && (arrTies[arrTies.length-1].last_NoteTick == oCursor.tick)) {
					//In theory there should be a 'reality-check' here to be sure string/fret/pitch
					//between the two notes I'm about to tie. I don't really have the data to do
					//that here in this simulation. But in the real code I'll do that.
				console.log("---- Making a tie on TAB staff back at tick <", arrTies[arrTies.length-1].first_NoteTick, ">");
				curScore.selection.select(arrTies[arrTies.length-1].first_oTABnote, false);
				cmd("tie");
				arrTies.pop();
			} // End loop where we are pretenting to process pending ties at current cursor location.
			console.log("====| Completed Tie Processing");
			console.log("----| Array Listing After Tie Processing -->>");
			console.log("---- ---- array size <",arrTies.length, ">");
			for(var i=0; i<arrTies.length; i++) {
				console.log("---- ---- Note <", i, ">");
				console.log("---- ---- ---- oSMNNote's Tick <", arrTies[i].first_NoteTick, ">");
				console.log("---- ---- ---- oSMNNote's Pitch <", arrTies[i].first_oSMNnote.pitch, ">");
				console.log("---- ---- ---- oTABnote's Pitch <", arrTies[i].first_oTABnote.pitch, ">");
				console.log("---- ---- ---- End Note's Tick <", arrTies[i].last_NoteTick, ">\n");
			}
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
