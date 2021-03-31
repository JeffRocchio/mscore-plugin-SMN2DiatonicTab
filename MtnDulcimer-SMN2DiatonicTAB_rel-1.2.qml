//=============================================================================
//  MuseScore Plugin
//
//  This plugin reads a Standard Notation staff and generates the
//  diatonic+ TAB for the Mountain Dulcimer onto an existing TAB staff.
//  
//  **** See Key Usage Assumptions below ****
//
//  This plugin created by Jeffrey Rocchio and is free for anyone to use or
//  modify.
//
//   NOTE: This file was edited with the KDE Kate editor, indentation is with
//   tabs, tab-width: 4 space equlivant.
//
//   NOTE: Sections of code warranting verbose documentation are noted with 
//   references, in the form "See CD-##," which are rows in a table in 
//   a LibreOffice document which can be found in my github repository
//   SMN-to-Diatonic-Dulcimer-TAB_CodeDocumentation.odt.
//
//   NOTE: Learning QML, the Musescore plugin API, and even to some degree
//   Musecore itself, is a steep hill to climb. Due to this, and the ultra-
//   concise plugin documentation, figuring out how make this plugin took a
//   lot of experimentation, a lot of trial-and-error. So my code is a bit
//   verbose as I needed to really break each step down and use lots of
//   interim debug statements to work it out. I also wanted to keep good notes
//   on what I was doing. I've left the code kinda verbose. To trim down the 
//   documentation within the code I have moved much of it into a seperate
//   LibreOffice Writer document. References in the code of the form:
//   CD-## are pointers into that document for descriptions of what I think
//   I'm doing at that point in the code. The LibreOffice document is 
//   in my github repository for this plugin.
//=============================================================================

//------------------------------------------------------------------------------
//  KEY USAGE ASSUMPTIONS:
//  
//     1. At lease one chord on the SMN staff has been selected by the user.
//
//     2. The score being operated on consists of at least one SMN staff and 
//  one TAB staff; and the TAB staff was created using the Mtn Dulcimer
//  instrument.
//  
//     3. The TAB staff's properties accurately reflect the open string
//   tuning. If tuned in standard DAd, then per #2 above all is well. If
//   making TAB for a different tuning, then you will need to go into staff
//   properties and set the open string tuning to match.
//
//     4. The TAB staff is immediately below the SMN staff.
//
//     5. The 'half-frets' have to be added as a work-around, but adding
//  the '+' symbols as staff text. unfortunally I am unable to do a whole 
//  to fully control their placement as they are attached to an anchor on the 
//  staff, and not to an individual note. Consequently you may have to manually
//  fix up their size and position after the plugin runs; and anytime to make
//  formatting changes to the TAB staff.
//
//------------------------------------------------------------------------------

//------------------------------------------------------------------------------
//  1.2: Fixed last chord error
//  1.1: Added support for ties (3/25/2021)
//------------------------------------------------------------------------------




import QtQuick 2.0
import QtQuick.Dialogs 1.1
import MuseScore 3.0

MuseScore {
	version:  "1.2"
	description: "Generate Diatonc Mtn Dulcimer TAB from an SMN staff"
	menuPath: "Plugins.Mtn Dulcimer.SMN to Diatonic-TAB"

	QtObject { // oUserMessage
		id: oUserMessage
		
		//	PURPOSE: Is an error recording and reporting object, used
		//to provide error and warning messages to the user.
		
		property bool bError: false
		property int iMessageNumber: 0 // <-- Last trapped error
		readonly property var sUserMessage: [
					//	0: <-- All OK, No Error
		"OK",
					//	1:
		"Nothing Selected - please select 1 or more measures to transform and try again.",
					//	2:
		"Selected staff does not appear to be a TAB staff. Please double-check and try again.",
					//	3:
		"Selected staff appears to be a linked staff. Transforming will destroy the linked-to staff. 
		Please create a non-linked TAB staff, copy the linked TAB staff's content to that, 
		select the measure of that you wish to transform and try again.",
					//	4:
		"Unrecognized element on SMN staff. Don't know how to handle it.",
					//	5:
		"Selection appears to be invalid. Please clear your selection and try again. 
		Be sure to select whole measures, do not start with part of a measure.",
					//	6:
		"Cannot find a valid TAB staff immediately below your selected range.",
					//	7:
		"An error occurred trying to create tied note."
		]
		
		function getError() { return bError; }
		
		function setError(iMessageNum) {
			oUserMessage.bError = true;
			oUserMessage.iMessageNumber = iMessageNum;
		} // end function setError()
	
		function showError(bReset) {
			console.log("", oUserMessage.sUserMessage[oUserMessage.iMessageNumber]);
			if (bReset) { 
				oUserMessage.iMessageNumber = 0;
				oUserMessage.bError = false;
			}
		} // end function getError()
		
		function popupError() {
			
			errorDialog.openErrorDialog(qsTranslate("QMessageBox", sUserMessage[iMessageNumber]));
			
		} // end function popupError()

	} // end oUserMessage QtObject
	  
	QtObject { // oFretBoard
		id: oFretBoard

		//	PURPOSE: This forms an object that represents the 
		//Mountain Dulcimer fretboard
		
		property int iNumOfStrings: 3
		property var iStringTuning: [50, 57, 62]
		
		// ============================================ See CD-02 >
		readonly property var sHalfFretSymbol: "+"
		readonly property var nHalfFretXPosition: 1.3; 
		readonly property var nHalfFretYPositions: [0.10, 1.55, 3.10] 
		
		// ============================================ See CD-03 >
		readonly property var iTForm_Offsets: [
		0, 1, 1, 2, 2, 
		2, 3, 3, 4, 4, 
		4, 5, 5, 6, 6, 
		7, 7, 7, 8, 8, 
		9, 9, 9, 10, 10, 
		11, 11, 12, 12, 12
		]
		readonly property var bTForm_Halffrets: [
		false, true, false, true, false, 
		false, true, false, true, false, 
		false, true, false, true, false, 
		true, false, false, true, false,
		true, false, false, true, false,
		true, false, true, false, false
		]

		function convertChord() {
			//	PURPOSE: Given a chromatic set of chord notes, convert 
			//their pitches to diatonc+ pitches that will cause them
			//to appear with the right diatonic+ fret numbers once
			//Musecore writes them out to the TAB staff.
			//
			//	ASSUMES: 
			//		1.	QtObject oTABchordInfo holds the chromatc notes
			//			we will operate on (it's a global, so I'm just
			//			referencing here without trying to work out how to
			//			use QML as a real object oriented language).
			//		2.	Musecore orders notes in the chord.notes[] array
			//			from lowest pitch to highest, and we put our
			//			converted diatonc+ notes into our arrays in that
			//			same order.
			
			var bDEBUG = true;
			bDEBUG = false;
			
			if (bDEBUG) console.log("\n======== | In funct convertChord() | ________________________________________");
			
			//	The algorithm to get pitch is to (a) use the open string tuning
			//to obtain the chromatic fret number. Then (b) use the offset arrays
			//to adjust the pitch to what it needs to be to get the diatonic pitch
			//for that fret#. And then also set the Halffret flag.
			
			var iChromoPitch = 0;
			var iChromoFret = 0;
			var iDiatonicPitch = 0;
			var bDiatonicHalf = false;
			var iStringIdx = oFretBoard.iNumOfStrings-1; // <- Helps me process from highest pitch to lowest for the chord
			
			if (bDEBUG) { // DEBUG STATEMENTS
				console.log("      ----- | Num Notes in Chord: ", oTABchordInfo.iNumOfNotes);
				console.log("      ----- | Chromatic 1st Note ---| String <", oTABchordInfo.iNoteString[0], ">  Fret <", oTABchordInfo.iNoteFret[0], ">  Pitch <",oTABchordInfo.iNotePitch[0], ">  Half <",oTABchordInfo.iNoteHalf[0], ">");
			}
			
			// ============================================ See CD-01 >
			if (bDEBUG){  // DEBUG STATEMENTS
				/*console.log("      ----- The Incoming Chromo Chord Notes ----->");
				for (var i=oTABchordInfo.iNumOfNotes-1; i>=0; i--) {
					console.log("          ----- Note# [", i, "] Note Pitch <", oTABchordInfo.iNotePitch[i],">");
				} // end for loop */
			}

			iStringIdx = oFretBoard.iNumOfStrings-1; // <-- Start with highest pitch open string.
			for (var i=oTABchordInfo.iNumOfNotes-1; i>=0; i--) {
				iChromoPitch = oTABchordInfo.iNotePitch[i];
				while(iChromoPitch < oFretBoard.iStringTuning[iStringIdx]) {
					iStringIdx--;
				}
				iChromoFret = convertPitch(oTABchordInfo.iNotePitch[i], iStringIdx);
				oTABchordInfo.iNoteString[i] = iStringIdx;
				oTABchordInfo.iNoteFret[i] = iChromoFret - oFretBoard.iTForm_Offsets[iChromoFret];
				oTABchordInfo.iNotePitch[i] = iChromoPitch - oFretBoard.iTForm_Offsets[iChromoFret];
				oTABchordInfo.iNoteHalf[i] = oFretBoard.bTForm_Halffrets[iChromoFret];
				iStringIdx--;
			} // end for loop
			
			if (bDEBUG){ // DEBUG STATEMENTS 
				console.log(" ");
				console.log("      ----- The Converted TAB Chord Notes ----->");
				for (var i=0; i<oTABchordInfo.iNumOfNotes; i++) {
					console.log("          ----- Note on String# [", oTABchordInfo.iNoteString[i], "]  Fret <", oTABchordInfo.iNoteFret[i], ">  Pitch <",oTABchordInfo.iNotePitch[i], ">  Half <",oTABchordInfo.iNoteHalf[0],">");
				}
			}
			
			if (bDEBUG) console.log("\n======== | convertChord() RETURNing to caller ________________________________________>\n");
			
		} // end convertChord() function in QtObject oFretBoard
		
		function convertPitch(iPitch, iString) {
			//	PURPOSE: Given a chromatic pitch, and the string it needs to be placed on,
			//determine the chromatic fret# for that string.
			
			var iFret = 0;
			iFret = iPitch - oFretBoard.iStringTuning[iString];
			return iFret;
			
		} // end convertPitch
		
	} // end oFretBoard QtObject
	
	QtObject { // oTABchordInfo
		id: oTABchordInfo
		
		//	PURPOSE: This object represents a TAB chord that is to
		//mirror the SMN chord we are needing to write to the TAB staff.
		//	I am using this approach because I have been unable to 
		//find a way to build a new chord from scratch in
		//a newly created CHORD object. As soon as I add a note to my
		//newly created chord object Musescore crashes. Best I can figure
		//is because the duration value on the chord is 0/1. But I haven't 
		//been able to figure out how to set a chord's duration. So I am
		//falling back to building the new TAB chord's data into this
		//simulated object, then I'll have to add individual notes to the
		//TAB staff using this object's data so that Musecore will, 
		//internally, create the proper data structures.

		property int iNumOfNotes: 3
		property int iDurationNum: 1
		property int iDurationDem: 4
		property var oNoteTieForward: []		// <-- I need this to handle ties.
		property var oSMNnote: []				// <-- I need this to handle ties.
		property var oTABnote: []				// <-- I need this to handle ties.
		property var iNotePitch: [50, 57, 62]	// <- just setting defaults to std opening tuning.
		property var iNoteString: [0, 1, 2]
		property var iNoteFret: [0, 0, 0]
		property var iNoteHalf: [false, false, false]

	} // end oTABchordInfo QtObject
	
	QtObject { // oTABrestInfo
		id: oTABrestInfo
		property int iDurationNum: 1
		property int iDurationDem: 4
		
	} // QtObject oTABrestInfo

	QtObject { // oStaffInfo
		id: oStaffInfo
		
		//	PURPOSE: This object represents the two staffs we are operating on.
		
		property int iSMNstaffIdx: 0
		property int iTABstaffIdx: 1
		
		function getStaffInx(sStaff) {
				if (sStaff == "TAB") return oStaffInfo.iTABstaffIdx;
				else return oStaffInfo.iSMNstaffIdx
		}

		function setStaffInx(oCursor) {
			
			var bDEBUG = true;
			bDEBUG = false;
			
			if(bDEBUG) console.log("\n======== | In function oStaffInfo.setStaffInx() | =================================");
			
			oCursor.rewind(Cursor.SELECTION_START);
			oStaffInfo.iSMNstaffIdx = oCursor.staffIdx;
			oStaffInfo.iTABstaffIdx = oCursor.staffIdx + 1; // <-- For now I am assuming the TAB staff is right below the SMN staff.
			
			if(bDEBUG) { // DEBUG STATEMENTS
				console.log("----  SMN staff Index <", iSMNstaffIdx, ">");
				console.log("----  TAB staff Index <", iTABstaffIdx, ">");
			}

			if(bDEBUG) console.log("\n======== | oStaffInfo.setStaffInx() RETURNing to caller ________________________________________\n");
		} // end function setStaffInx()
		
	} // end QtObject oStaffInfo

	QtObject { // oSelection
		id: oSelection
		property int iUsrSelectStartTick: 0;
		property int iUsrSelectEndTick: 0;
		
		function storeUserRange(oCursor) {
			//   PURPOSE: Save the user's selected range
			// (as we may otherwise lose it in some of our
			// operations)
			//   ASSUMES:
			//		1.	oStaffInfo.setStaffInx() has been called
			//			prior to calling this function.
			
			var bDEBUG = true;
			bDEBUG = false;
			
			if(bDEBUG) oDebug.fnEntry(storeUserRange.name);
			
			oCursor.staffIdx = oStaffInfo.getStaffInx("SMN");
			oCursor.rewind(Cursor.SELECTION_START);
			oSelection.iUsrSelectStartTick = oCursor.tick;
			oCursor.rewind(Cursor.SELECTION_END);
			if (bDEBUG) console.log("---- Selection Start Tick <", oSelection.iUsrSelectStartTick, "> ,  Cursor Tick at Selection End <", oCursor.tick, ">");
			if (oCursor.tick === 0) {
				//	This happens when the selection includes
				//the last measure of the score. rewind(SELECTION_END) goes 
				//1-tick beyond the last segment (where there's none) 
				//and sets tick=0
				if (bDEBUG) console.log(" **** | We have the Last Measure Selection problem | ****");
				if (bDEBUG) console.log("---- ---- Tick of Last Segment in Score <", curScore.lastSegment.tick, ">, which is a <", curScore.lastSegment.segmentType, ">");
				oSelection.iUsrSelectEndTick = curScore.lastSegment.tick + 1;
			} else {
				oSelection.iUsrSelectEndTick = oCursor.tick;
			}
			if (bDEBUG) console.log("    ---- Selection Start Tick <", oSelection.iUsrSelectStartTick, "> ,  EndTick <", oSelection.iUsrSelectEndTick, ">");

			if(bDEBUG) oDebug.fnExit(storeUserRange.name);
			
		} // end oSelection.storeUserRange()
		
		function clearSelection(oCursor) {
			//   PURPOSE: Clear any selection in the score. This function
			//is used by writeTABties(), and perhpas by other functions 
			//have to rely on the cmd() interface to add specific note 
			//elements not otherwise accessable through the plugin API.
			//   ASSUMES:
			//		1.	oStaffInfo.setStaffInx() has been called
			//			prior to calling this function.
			
			curScore.selection.clear();

			
		} // end oSelection.clearSelection();
		
		function setSelectionRange(oCursor) {
			//   PURPOSE: Set the score's selection range to the user's 
			//originally selected range, on the SMN staff. 
			//	I use this after moving the range to the TAB staff for 
			//the TAB staff clear/delete operation. I reset it back to 
			//the SMN staff so that the user retains visibility into the 
			//portion of the score that was operated on once the plugin 
			//ends. 
			//	I do also depend on this for the cursor.rewind() operations, 
			//although I could revise the code to use tick locations to move 
			//the cursor if for some reason I chose to not reset the 
			//original user range.
			//   ASSUMES:
			//		1.	oStaffInfo.setStaffInx() has been called
			//			prior to calling this function.
			//		2.	oSelection.storeUserRange() has already
			//			been called.
			
			var bDEBUG = true;
			bDEBUG = false;
			
			if(bDEBUG) oDebug.fnEntry(setSelectionRange.name);
				
			oCursor.staffIdx = oStaffInfo.getStaffInx("SMN");
			var bRangeSetOk = curScore.selection.selectRange(oSelection.iUsrSelectStartTick, oSelection.iUsrSelectEndTick, oCursor.staffIdx, oCursor.staffIdx+1);
			if (!bRangeSetOk) {
				oUserMessage.setError(5);
				return false;
			}
			curScore.endCmd(); // <-- this is necessary for range to be 'active' in Musecore for following operations.
			
			if(bDEBUG) oDebug.fnEntry(setSelectionRange.name);
				
			return true;
			
		} // end function setSelectionRange()
		
		function trapNotStartOfMeasure(oCursor) {
			//   PURPOSE: Detect if the user's selection begins on a measure 
			//boundary. If not, move the selection back to start of measure. 
			//See CD-08 for why we have to do this.
			//   ASSUMES:
			//		1.	oStaffInfo.setStaffInx() has been called
			//			prior to calling this function.
			//		2.	oSelection.storeUserRange() has already
			//			been called.
			
			var bDEBUG = true;
			bDEBUG = false;
			
			if(bDEBUG) oDebug.fnEntry(trapNotStartOfMeasure.name);
			
					// ============================================ See CD-08 >
			oCursor.rewind(Cursor.SELECTION_START);
			if (oSelection.iUsrSelectStartTick > oCursor.measure.firstSegment.tick) {
				oSelection.iUsrSelectStartTick = oCursor.measure.firstSegment.tick;
				if (!oSelection.setSelectionRange(oCursor)) {
					oUserMessage.setError(5);
					return false;
				}
			}
			
			if(bDEBUG) oDebug.fnExit(trapNotStartOfMeasure.name);
			
			return true;
		
		} // end function trapNotStartOfMeasure()

		function deleteSelection(oCursor, iStartTick, iEndTick, sStaff) {
			//	PURPOSE: cleanly delete a selection range. Used to clear
			//out the user-selected range of the TAB staff before we 
			//begin writing onto it.
			//============================================ See CD-07 >
			

			var bDEBUG = true;
			//bDEBUG = false;
			
			if(bDEBUG) oDebug.fnEntry(deleteSelection.name);

			if (bDEBUG) console.log("---- To Be Selected --| Tick: Start <", iStartTick, "> End <", iEndTick, "> Staff Idx: Start <", oStaffInfo.getStaffInx(sStaff), "> End <", oStaffInfo.getStaffInx(sStaff)+1, ">\n");
			
					//	Create the selection range.
			var bRangeSetOk = curScore.selection.selectRange(iStartTick, iEndTick, oStaffInfo.getStaffInx(sStaff), oStaffInfo.getStaffInx(sStaff)+1);
			if (!bRangeSetOk) {
				oUserMessage.setError(5);
				return false;
			}
			curScore.endCmd(); // <-- this is necessary for range to be 'active' in Musecore for following operations.
			
			if (bDEBUG) {
				oCursor.staffIdx = oStaffInfo.getStaffInx(sStaff);
				console.log("---- Was Selected ---| Segment: Start <", curScore.selection.startSegment, 
					"> End <", curScore.selection.endSegment, 
				"> ---| Staff: Start <", curScore.selection.startStaff, 
				"> End <", curScore.selection.EndStaff,
				">\n");
				oCursor.rewind(Cursor.SELECTION_START);
				console.log("---- Cursor rewind to START: On Staff <", oCursor.staffIdx, "> At Tick <", oCursor.tick, ">\n");
				oCursor.rewind(Cursor.SELECTION_END);
				console.log("---- Cursor rewind to END: On Staff <", oCursor.staffIdx, "> At Tick <", oCursor.tick, ">");
			}
			
			cmd("delete");
			
			if(bDEBUG) oDebug.fnExit(deleteSelection.name);
			
			return true;
			
		} // end function deleteSelection()
		
	} // end QtObject oSelection
	
	QtObject { // oTiesPending
		id: oTiesPending

		//	PURPOSE: This object represents a list of ties-forward we have
		//sensed on the SMN staff which are waiting for us to find their
		//matching tied-to notes to put the tie on the right TAB notes.
		//	Note that it did take me a lot of experimentation to work out 
		//how to do this. See CD-10 for the gory details.
		
					//	This is a list of pending ties, with associated
					//meta-data I need in order to place the tie when
					//we arrive at the matching not. The columns in this
					//array are: 
					//{ tabNote_firstoTABnote, tabNote_Pitch, tabNote_String, tabNote_Fret, oTie, tick_lastNote, smn_oSMNnote }
		property var arrTies: [] // 

		function writeTiesAtTick(oCursor) {
			//	PURPOSE: Write out all pending ties for the current 
			//cursor location.
			//
			//	ASSUMES: 
			//		1.	All forward-ties from previous ticks have been
			//			sensed and added to the arrTies[] list.
			
			var bDEBUG = true;
			bDEBUG = false;
			
			if (bDEBUG) console.log("\n======== | In funct oTiesPending.writeTiesAtTick() <", oCursor.tick, "> | =================================");

			var iString = 0;
			var iFret = 0;
			
					//	First, sort the array.
			oTiesPending.sortList();
			if(bDEBUG) listTieArray(" [In writeTiesAtTick() Prior to Writing the Ties] ");
			
					//	Now process the subset of the sorted array that
					//corresponds to the current cursor tick.
					//Tricky part is I want to make sure the TAB notes
					//I'm about to tie together match up with same fret/string.
					//So I'm using an inner loop for the match-up.
			while((arrTies.length > 0) && (arrTies[arrTies.length-1].tick_lastNote == oCursor.tick)) {
				iString = arrTies[arrTies.length-1].tabNote_String;
				iFret = arrTies[arrTies.length-1].tabNote_Fret;
				for(var i=oTABchordInfo.iNumOfNotes-1; i>=0; i--) {
					if(bDEBUG) console.log("---- i [", i, "]: TIE String <", iString, "> Fret <", iFret, "> || Chord Note's String <", oTABchordInfo.iNoteString[i], "> Fret <", oTABchordInfo.iNoteFret[i], ">");
					if((oTABchordInfo.iNoteString[i] == iString) && (oTABchordInfo.iNoteFret[i] == iFret)) {
						if(bDEBUG) console.log("---- Made a Match - Writing tie to TAB staff");
						curScore.selection.select(arrTies[arrTies.length-1].tabNote_firstoTABnote, false);
						cmd("tie");
						break;
					} // end if 
				} // end for loop
				arrTies.pop(); // <-- match or no match, remove from the array.
			} // end while loop 
			
			if(bDEBUG) listTieArray(" [State of array AFTER Writing the Ties] ");

			if (bDEBUG) console.log("\n======== | oTiesPending.writeTiesAtTick() RETURNing to caller ________________________________________>\n");
			
		} // end function writeTiesAtTick()
		
		function listTieArray(sHeader) {
			//	PURPOSE: Used for debug purposes to list the pending ties
			//array in the debug console.
			
			var firstTick = 0;
			console.log("\n---- Pending Tie Array Listing ", sHeader," -------->>");
			console.log("---- ---- array size <",arrTies.length, ">");
			for(var i=0; i<arrTies.length; i++) {
				console.log("---- ---- Loop Index <", i, ">");
				firstTick = arrTies[i].oTie.startNote.parent.parent.tick;
				console.log("---- ---- ---- oTie: 1st Note Tick <", firstTick, "> Last Note Tick <", arrTies[i].tick_lastNote, ">");
				console.log("---- ---- ---- oSMNNote's Pitch <", arrTies[i].smn_oSMNnote.pitch, ">");
				console.log("---- ---- ---- tabNote: Object <", arrTies[i].tabNote_firstoTABnote, "> Pitch <", arrTies[i].tabNote_Pitch, "> String <", arrTies[i].tabNote_String, "> Fret <", arrTies[i].tabNote_Fret, ">");
			}
			console.log("");
			
		} // end function listTieArray()
		
		function insertPendingTie(oTABchordInfo_Index) {
			//	PURPOSE: Add a new pending tie to the list.
			//
			//	TAKES: 
			//		1.	An index into the various oTABchordInfo property 
			//			arrays. This is a kludge of a way to pass the
			//			oTABchordInfo object into this function. Doing it
			//			this way because I'm not so facile with javascript
			//			or QML to make proper objects.
			//
			//	ASSUMES:
			//		1.	The oTABchordInfo properties and arrays
			//			have been fully populated so that we have all
			//			the data, objects and variables we need to
			//			create the pending tie list row.
			
			var bDEBUG = true;
			bDEBUG = false;

			var lastTick = 0; 
			
			if (bDEBUG) console.log("\n======== | In funct oTiesPending.insertTie() | =================================");

			lastTick = oTABchordInfo.oNoteTieForward[oTABchordInfo_Index].endNote.parent.parent.tick;
			arrTies.push({ // <-- See CD-10 Key Learning for why this must be done in this syntax, and why 'push' must be used.
				tabNote_firstoTABnote:oTABchordInfo.oTABnote[oTABchordInfo_Index], 
				tabNote_Pitch: oTABchordInfo.iNotePitch[oTABchordInfo_Index],
				tabNote_String: oTABchordInfo.iNoteString[oTABchordInfo_Index],
				tabNote_Fret: oTABchordInfo.iNoteFret[oTABchordInfo_Index],
				oTie: oTABchordInfo.oNoteTieForward[oTABchordInfo_Index],
				tick_lastNote: lastTick,
				smn_oSMNnote: oTABchordInfo.oSMNnote[oTABchordInfo_Index],
			})
			
			if (bDEBUG) listTieArray("(After an Insertion)");
			
			if (bDEBUG) console.log("\n======== | oTiesPending.insertTie() RETURNing to caller ________________________________________>\n");
			
		} // end function oTiesPending.insertTie()
		
		function sortList() {
			//	PURPOSE: Sort the arrTies[] array by tick_lastNote.
			//(We do this so that we can process the subset of pending ties
			//at the appropriate cursor locations as we walk the staff.)
			//	ASSUMES: 
			//		1.	
			
			var bDEBUG = true;
			bDEBUG = false;
			
			if (bDEBUG) console.log("\n======== | In funct oTiesPending.sortList() | =================================");
			
			arrTies.sort(function(a,b){
				return -1 * (a.tick_lastNote - b.tick_lastNote); // <- reverse order as I am pushing/popping from bottom of list.
				});
			
			if (bDEBUG) listTieArray(" ** After Sorting **");
			
			if (bDEBUG) console.log("\n======== | convertChord() RETURNing to caller ________________________________________>\n");
			
		} // end function sortList()
		
	} // end QtObject oTiesPending
	
	QtObject { // oDebug
		id: oDebug

		//PURPOSE:
		//	Provide services that help in debugging. This is primarily 
		//services to create console.log print statements.
		
		function fnEntry(fnName) {
				console.log("");
				console.log("======== | In function ", fnName, "() | =================================\n");
		}
		
		function fnExit(fnName) {
			console.log("");
			console.log("======== | ", fnName, "() RETURNing to caller ||\n");
		}
		
	} // end QtObject oDebug
	
	
	function assessValidity(oCursor) {
		//   PURPOSE: Prior to attempting any transformation, see 
		//if it appears that the user has set a valid selection
		//range; and that we have valid staffs to read from and
		//write to. We want to check for: 
		//	1.	Is there a selection - one or more chords/measures?
		//	2.	Is there a TAB staff right below the staff the selection
		//		range is on?
		//	3.	UNABLE to find a way to check for this: Is the staff 
		//'Linked' to another staff (if so, we
		//don't want to operate on it as it will totally destroy
		//the arrangement on whatever staff it is Linked to. And
		//unfortunally it is not possible to unlink it.
		//   RETURNS:
		//		1.	true if all is well, false if not. And if true:
		//		2.	Selected user range, the staff indicies, and 
		//			the string data will have been stored in 
		//			oSelection, oStaffInfo, and oFretBoard
		//			objects.
		//		3.	If false, the oUserMessage object will contain
		//an error number which can be used to inform the user.
		
		var bDEBUG = true;
		bDEBUG = false;

		if(bDEBUG) oDebug.fnEntry(assessValidity.name);
		
					//   1st: Do we have a selection?
		if(bDEBUG) {
			console.log("---- Inspecting the Selection ---|");
			console.log("---- ---- # of Elements Selected <", curScore.selection.elements.length, ">");
			console.log("---- ---- Range or no Range? <", curScore.selection.isRange, ">");
		}
		if (curScore.selection.elements.length==0) {
			oUserMessage.setError(1);
			return false;
		}
		
					//	We have a selection, but now is it a range (vs just 
					//some single notes/rests)?
		if (!curScore.selection.isRange) {
			oUserMessage.setError(5);
			return false;
		}
					
		
					//	We have a valid selection, now store the range.
		oSelection.storeUserRange(oCursor);
		

					//	Now set the staff index values.
		oStaffInfo.setStaffInx(oCursor);
		if(bDEBUG) { // DEBUG STATEMENTS
			console.log("---- SMN staff Index <", oStaffInfo.getStaffInx("SMN"), ">");
			console.log("---- TAB staff Index <", oStaffInfo.getStaffInx("TAB"), ">");
			console.log(" ");
		}
		
					//	Make sure selection starts on a measure boundary.
		if (!oSelection.trapNotStartOfMeasure(oCursor)) {
			oUserMessage.setError(5);
			return false;
		}
		
					//	See if the presumed TAB staff looks right
					// ============================================ See CD-06 >
		var iTABstaffIdx = oStaffInfo.getStaffInx("TAB");
		var iStavesInScore = curScore.nstaves;
		if(bDEBUG) {
			console.log("---- | Starting TAB Staff Validation Process | ----");
			console.log("---- SMN staff Index <", oStaffInfo.getStaffInx("SMN"), ">");
			console.log("---- # staves in score <", iStavesInScore, ">");
		}
		if(iStavesInScore-1 < iTABstaffIdx) {
			if(bDEBUG) console.log("---- ---- ---- ERROR ->> TAB staff index value exceeds total # of staves in score");
			oUserMessage.setError(6);
			return false;
		}
					//	Get the Part the TAB staff is in, 
					//see if it looks OK; and if so, get the string
					//information - # of strings and tuning.
		oCursor.rewind(Cursor.SELECTION_START);
		oCursor.staffIdx = oStaffInfo.getStaffInx("TAB");
		var oTABstaff = oCursor.element.staff;
		var oTABpart = oCursor.element.staff.part;
		if(bDEBUG) {
			console.log("---- ----TAB's Staff Info ->> ");
			console.log("---- ---- ---- Element Type <", oTABstaff.name,">");
			console.log("---- ---- ---- Part this Staff Belongs To:", oTABstaff.part.partName);
			console.log("---- ----TAB's Part Info ->> ");
			console.log("---- ---- ---- Part longName <", oTABpart.longName,">");
			console.log("---- ---- ---- Part startTrack <", oTABpart.startTrack,">");
			console.log("---- ---- ---- Part endTrack <", oTABpart.endTrack,">");
			console.log("---- ---- ---- Does Part have a TAB staff? <", oTABpart.hasTabStaff,">");
			console.log("---- ---- ---- Number of instruments in Part <", oTABpart.instruments.length,">");
		}
		if (!oTABpart.hasTabStaff) {
			if(bDEBUG) console.log("---- ---- ---- ERROR ->> Presumed TAB staff's part has no TAB staff in it.");
			oUserMessage.setError(6);
			return false;
		}
		if(bDEBUG) {
			console.log("---- ---- TAB's Part Does Have a TAB staff within it, so now we'll get it's string data.");
			if(bDEBUG) console.log(" ");
		}
					//	Get the stingData object to read the open string tuning.
		if(bDEBUG) console.log(" ");
		var iStringCount = 0;
		for (var i=0; i<oTABpart.instruments.length; i++) {
			if(bDEBUG) console.log("----  ---- ---- Instrument [", i, "] longName <", oTABpart.instruments[i].longName,">");
			if(oTABpart.instruments[i].stringData != null) { // inspect instruments in part for stringData info
				oFretBoard.iNumOfStrings = oTABpart.instruments[i].stringData.strings.length;
				for (var s=0; s<oFretBoard.iNumOfStrings; s++) { // Get the open tuning data
					if(bDEBUG) console.log("----  ---- ---- String [", s, "] Pitch: ", oTABpart.instruments[i].stringData.strings[s].pitch); 
					oFretBoard.iStringTuning[s] = oTABpart.instruments[i].stringData.strings[s].pitch;
				} // end stingData fetching loop
			} // end instrument inspection loop
		} // end instrument seeking loop
		
		if(bDEBUG) oDebug.fnExit(assessValidity.name);
		return true;
		
	} // end assessValidity()
	
	function writeTABchord(oCursor) {
		//	PURPOSE: Using the chord data in oTABchordInfo object, write that
		//chord to the TAB staff.
		//	ASSUMES:
		//		1.	oTABchordInfo is populated with a valid diatonc+ chord
		//			representation.
		//		2.	The notes in the arrays of oTABchordInfo are ordered
		//			from lowest pitch to highest. I.e., if there are three
		//			notes in the chord, then oTABchordInfo.iNotePitch[0] holds
		//			the lowest pitch note. Implication being that that note
		//			would go onto string #3 (bass string); and we should give 
		//			Musecore that note last; we want Musecore to add the 
		//			highest pitched note first as believe that doing it in that
		//			order will give us the best fret numbering outcome.
		//	RETURNS:
		//		1.	Upon return the cursor is on the tick and staff
		//			it was on when coming into this function.
		
		var bDEBUG = true;
		//bDEBUG = false;
		
		if(bDEBUG) oDebug.fnEntry(writeTABchord.name);
		
		var bAdd2Chord = false;
		var iPriorTick = 0; // See CD-05, Key Learning-2
		
		if (bDEBUG) {
			console.log("    ---- At Tick |", oCursor.segment.tick,"| ----");
			console.log("    ---- SMN chord | # of notes [", oCursor.element.notes.length, "]---->");
			for (var n=0; n<oCursor.element.notes.length; n++) {
				console.log("    ---- ---- Note <", n, "> Pitch <", oCursor.element.notes[n].pitch, ">");
			}
			console.log(" ");
			console.log("    ---- oTABchordInfo | # of notes [", oTABchordInfo.iNumOfNotes, "]---->");
			for (var n=0; n<oTABchordInfo.iNumOfNotes; n++) {
				console.log("    ---- ---- Note <", n, "> Pitch <", oTABchordInfo.iNotePitch[n], "> HalfFret <",oTABchordInfo.iNoteHalf[n],"> String <", oTABchordInfo.iNoteString[n],"> backTie <", oTABchordInfo.oNoteBackTie,">");
			}
			console.log(" ");
		}
		
		oCursor.staffIdx = oStaffInfo.iTABstaffIdx;
		oCursor.setDuration(oTABchordInfo.iDurationNum, oTABchordInfo.iDurationDem);
		
					// ============================================ See CD-05 >
		for (var i=oTABchordInfo.iNumOfNotes-1; i>=0; i--) { // <-- Post the notes to the TAB staff highest pitch to lowest.
			if (bDEBUG) console.log("    ---- Loop Index <", i, " Tick <", oCursor.segment.tick, "> Note to Add: Pitch <", oTABchordInfo.iNotePitch[i], "  Fret# <", oTABchordInfo.iNoteFret[i], "> HalfFret <", oTABchordInfo.iNoteHalf[i], ">");
			iPriorTick = oCursor.segment.tick; 	//	For testing if last note in score.
			oCursor.addNote(oTABchordInfo.iNotePitch[i], bAdd2Chord);
			if (bAdd2Chord==false) bAdd2Chord=true; // <-- toggle true after writing 1st note.
			if(oCursor.segment.tick > iPriorTick) oCursor.prev(); // <-- Move cursor back to note we just added.
			oCursor.element.notes[0].play = false; // <-- turn MIDI play off for all TAB notes.
					// For handling ties. ========================= See CD-10 >
			oTABchordInfo.oTABnote[i] = oCursor.element.notes[0];
			if(oTABchordInfo.oNoteTieForward[i] != null) oTiesPending.insertPendingTie(i);
			if (oTABchordInfo.iNoteHalf[i]) {
					// ============================================ See CD-02 >
				if (bDEBUG) console.log("   ---- ---- | Last Added Note is a Half-Fret |---- ");
				//oCursor.element.notes[0].color = "#aa0000"; <-- calls attention to the half-fret notes, if desired.
				var half = newElement(Element.STAFF_TEXT);
				oCursor.add(half);
				half.sizeSpatiumDependent = true;
				half.autoplace = false;
				half.placement = Placement.ABOVE;
				half.text = oFretBoard.sHalfFretSymbol;
				half.offsetX = oFretBoard.nHalfFretXPosition;
				half.offsetY = oFretBoard.nHalfFretYPositions[oTABchordInfo.iNoteString[i]];
			} // end the half-note if() stmt
		} // end the note-adding for() loop
		
		oTiesPending.writeTiesAtTick(oCursor);
		
		oCursor.staffIdx = oStaffInfo.iSMNstaffIdx; // <-- restore cursor to SMN staff.

		if(bDEBUG) oDebug.fnExit(writeTABchord.name);
		
	} // end writeTABchord()
	
	function writeTABrest(oCursor) {
		//	PURPOSE: Using the rest data in oTABrestInfo object, write that
		//rest to the TAB staff.
		//	ASSUMES:
		//		1.	oTABrestInfo is populated with a valid rest
		//			representation.
		//	RETURNS:
		//		1.	Upon return the cursor is either left in, or repositoned
		//			back to the tick and staff it was on when coming into 
		//			this function.
		
		var bDEBUG = true;
		bDEBUG = false;

		if(bDEBUG) oDebug.fnEntry(writeTABrest.name);
		
		oCursor.staffIdx = oStaffInfo.iTABstaffIdx;
		oCursor.setDuration(oTABrestInfo.iDurationNum, oTABrestInfo.iDurationDem);
		if (bDEBUG) console.log("   --- Before Adding Rest: On Staff <", oCursor.staffIdx, "> At Tick: <", oCursor.segment.tick,">");
		oCursor.addRest();
		oCursor.prev(); // restore cursor tick location.
		oCursor.staffIdx = oStaffInfo.iSMNstaffIdx; // <-- restore cursor back to SMN staff.
		if (bDEBUG) console.log("   --- After  Adding Rest: On Staff <", oCursor.staffIdx, "> At Tick: <", oCursor.segment.tick,">");
		
		if(bDEBUG) oDebug.fnExit(writeTABrest.name);
	} // end writeTABrest
	
	function writeTABelement(oCursor, sTabElement) {
		//	PURPOSE: Given an element obtained from the SMN staff,
		//transform it into an element we'll write to the TAB staff.
		//	ASSUMES:
		//		1. nothing
		//   RETURNS:
		//		1. Element type name.
		
		var bDEBUG = true;
		bDEBUG = false;

		if(bDEBUG) oDebug.fnEntry(writeTABelement.name);
		
		if (bDEBUG) console.log("    ---- Element Type to Write: ", sTabElement);
		switch (sTabElement) {
			
			case "Chord":
				writeTABchord(oCursor);
				break;
				
			case "Rest":
				if (bDEBUG) console.log("   --- In CASE 'Rest'");
				writeTABrest(oCursor);
				break;
				
			default:
				oUserMessage.setError(4);
				break;
		}
		
		if(bDEBUG) oDebug.fnExit(writeTABelement.name);
	} // writeTABelement()
	
	function buildTABchord(oSMNelement) {
		//	PURPOSE: Given a chord obtained from the SMN staff,
		//populate the oTABchordInfo data structure so that it can 
		//then be written /out to the TAB staff as a matching chord.
		//	This includes populating info that we'll need for ties.
		//	ASSUMES:
		//		1.	The passed-in parameter is a valid chord object
		//			obtained from the SMN staff.
		//		2.	There are 3 or less notes in the SMN chord. If
		//			there are more than 3 notes, we are only going
		//			to use the first three.
		//		3.	Musecore reliably returns notes in the chord.notes[]
		//			array in sorted pitch order, lowest pitch first (i.e.,
		//			chord.notes[0] holds lowest pitch note.
		//   RETURNS:
		//		1.	oTABchord global object is populated and ready 
		//			to be posted to the TAB staff.
		//		2.	oTiesPending global object is populated with
		//			new list entries if we have sensed a tie-foward.
		//		3.	TRUE if successful, FALSE otherwise.
		
		var bDEBUG = true;
		bDEBUG = false;
		
		if(bDEBUG) oDebug.fnEntry(buildTABchord.name);
		
		var oSMNchord = oSMNelement;
		
		if (bDEBUG) {
			console.log("    ---- SMN chord | # of notes [", oSMNchord.notes.length, "]---->");
			for (var n=0; n<oSMNchord.notes.length; n++) {
				console.log("    ---- ---- Note [", n, "] Pitch <", oSMNchord.notes[n].pitch, ">");
				if(oSMNchord.notes[n].tieForward != null) console.log("    ---- ---- Note [", n, "] has a Tie Forward: startNote Pitch <", oSMNchord.notes[n].tieForward.startNote.pitch, "> endPitch <", oSMNchord.notes[n].tieForward.endNote.pitch, ">");
				if(oSMNchord.notes[n].tieBack != null) console.log("    ---- ---- Note [", n, "] has a Tie Back: startNote Pitch <", oSMNchord.notes[n].tieBack.startNote.pitch, "> endPitch <", oSMNchord.notes[n].tieBack.endNote.pitch, ">");
			}
			console.log(" ");
		}
		
		oTABchordInfo.iNumOfNotes = oSMNchord.notes.length; // <-- must be set here so below trap can adjust it if needed.
		
					//	Trap condition where the number of notes 
					//in the chord exceeds the number of strings
					//on the instrument/TAB.
					// ============================================ See CD-04 >
		var iLoopOffset = 0;
		if (oSMNelement.notes.length > oFretBoard.iNumOfStrings) {
			oTABchordInfo.iNumOfNotes = oFretBoard.iNumOfStrings; // <-- Go ahead and set this to instrument max.
			iLoopOffset = oSMNelement.notes.length - oFretBoard.iNumOfStrings;
		}
		
		oTABchordInfo.iDurationNum = oSMNchord.duration.numerator;
		oTABchordInfo.iDurationDem = oSMNchord.duration.denominator;
		for (var i=0+iLoopOffset; i<oTABchordInfo.iNumOfNotes+iLoopOffset; i++) {
			oTABchordInfo.iNotePitch[i-iLoopOffset] = oSMNchord.notes[i].pitch;
			oTABchordInfo.iNoteHalf[i-iLoopOffset] = false;
			oTABchordInfo.oSMNnote[i-iLoopOffset] = oSMNchord.notes[i]; // TODO: I don't think I really use this | <-- Need this for building pending tie list.
			oTABchordInfo.oNoteTieForward[i-iLoopOffset] = oSMNchord.notes[i].tieForward;
		}
		
		oFretBoard.convertChord();

		if(bDEBUG) oDebug.fnExit(buildTABchord.name);
	} // end buildTABchord()
	
	function buildTABrest(oSMNelement) {
		//	PURPOSE: Given a rest element obtained from the SMN staff,
		//populate the oTABrestInfo data structure so that it can 
		//then be written out to the TAB staff as a matching rest.
		//	ASSUMES:
		//		1.	The passed-in parameter is a valid rest object
		//			obtained from the SMN staff.
		
		var bDEBUG = true;
		bDEBUG = false;
		
		if(bDEBUG) oDebug.fnEntry(buildTABrest.name);
		
		var oSMNrest = oSMNelement;
		
		oTABrestInfo.iDurationNum = oSMNrest.duration.numerator;
		oTABrestInfo.iDurationDem = oSMNrest.duration.denominator;
		if (bDEBUG) console.log("   --- Rest duration <", oTABrestInfo.iDurationNum, " / ", oTABrestInfo.iDurationDem, ">");
		
		if(bDEBUG) oDebug.fnExit(buildTABrest.name);
		
	} // end buildTABrest()
	
	function buildTABelement(oSMNelement) {
		//	PURPOSE: Given an element obtained from the SMN staff,
		//transform it into an element we'll write to the TAB staff.
		//	ASSUMES:
		//		1. nothing
		//   RETURNS:
		//		1. Element type name.
		
		var bDEBUG = true;
		bDEBUG = false;

		if(bDEBUG) oDebug.fnEntry(buildTABelement.name);
		
		var sElementType = oSMNelement.name;
		if (bDEBUG) console.log("   --- oSMNelement.name: ", oSMNelement.name);
		
		switch (oSMNelement.type) {
			
			case Element.CHORD:
				buildTABchord(oSMNelement);
				break;
				
			case Element.REST:
				if (bDEBUG) console.log("   --- In CASE 'Rest'");
				buildTABrest(oSMNelement);
				break;
				
			default:
				oUserMessage.setError(4);
				break;
		}

		if(bDEBUG) oDebug.fnExit(buildTABelement.name);
		return sElementType;
		
	} // buildTABelement()
	
	function makeTAB(oCursor) {
		//	PURPOSE: Walk through the SMN staff, fetch all it's relevant
		//elements, translate those into their TAB counterparts, and write
		//those onto the TAB staff.
		//	ASSUMES: 
		//		1.	We have successfully passed the assessValidity() tests.
		//		2.	For now we only processing the notes - not ties, slurs
		//			etc, as I don't yet know how to deal with those
		//			elements.

		var bDEBUG = true;
		//bDEBUG = false;
		
		if(bDEBUG) oDebug.fnEntry(makeTAB.name);
		
		var sTabElementType;
		
					//	OK, now iterate through the score until
					//we reach the end of the selection or the score.
		if (bDEBUG)  console.log("---- | Entering while loop that walks the SMN staff ---->>")
		oCursor.rewind(Cursor.SELECTION_START);
		while (oCursor.segment && oCursor.tick < oSelection.iUsrSelectEndTick) {
			if (bDEBUG)  console.log("---- ---- makeTAB()'s while loop says: Next element Type on SMN Staff <", oCursor.staffIdx, "> at Tick <", oCursor.tick, "> is a <", oCursor.element.name, ">");
			sTabElementType = buildTABelement(oCursor.element);
			writeTABelement(oCursor, sTabElementType);
			oCursor.next();
		}

		if(bDEBUG) oDebug.fnEntry(makeTAB.name);
	} // end of makeTAB()
	

//==== PLUGIN RUN-TIME ENTRY POINT =============================================

	onRun: {
		console.log("********** RUNNING **********");

		var oCursor = curScore.newCursor()
		
					//	Check that our selections and staffs look
					//valid for what we want to do. 
					//	Also note that the assessValidity() function will
					//initilize the oSelection, oStaffInfo, and oFretBoard
					//objects as well.
		if (!assessValidity (oCursor)) {
			oUserMessage.popupError();
		}
					//	All looks OK, so let's make the TAB.
		else { 
			var iStartTick = oSelection.iUsrSelectStartTick;
			var iEndTick = oSelection.iUsrSelectEndTick;
			if (!oSelection.deleteSelection(oCursor, iStartTick, iEndTick, "TAB")) {
				oUserMessage.popupError();
				Qt.quit();
				return;
			};
			oSelection.setSelectionRange(oCursor); // <-- reset the selection back to user's original on the SMN staff
			makeTAB(oCursor); // <-- OK, all looks valid, go do it.
		}

		console.log("********** QUITTING **********");
		Qt.quit();

	} //END OnRun

	
	
//==== PLUGIN USER INTERFACE OBJECTS ===========================================

	MessageDialog {
		id: errorDialog
		visible: false
		title: qsTr("Error")
		text: "Error"
		onAccepted: {
			Qt.quit()
		}
		function openErrorDialog(message) {
			text = message
			open()
		}
	}
	

} // END Musescore

