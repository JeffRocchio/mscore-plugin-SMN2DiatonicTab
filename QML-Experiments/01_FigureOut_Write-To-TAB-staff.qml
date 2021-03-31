//=============================================================================
//  MuseScore
//  Music Composition & Notation
//
//  Copyright (C) 2012-2017 Werner Schweer
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License version 2
//  as published by the Free Software Foundation and appearing in
//  the file LICENCE.GPL
//=============================================================================

import QtQuick 2.0
import MuseScore 3.0

MuseScore {
      version:  "3.0"
      description: "Trying to learn how to write to a TAB staff"
      menuPath: "Plugins.WriteToTAB"

	QtObject {
		id: oDulciFret
		property int fret: 0
		property bool addPlus: false
		property int pitch: 0
	  }
	  
	  
	function addNewNotes(measures, notesToWrite, startPitch, cursor) {
		console.log("In funct addNewNotes");

		cursor.setDuration(1, 4);
		notesToWrite = measures * 4; // assuming 4/4 time sig.
		curScore.startCmd();
		for (var i=1; i <= notesToWrite; i++) {
			cursor.addNote (startPitch, false);
			cursor.previous;
			cursor.addNote (startPitch-12, true);
			cursor.next;
		}
		curScore.endCmd();
		
		// RESULT: This does work to add notes to a TAB staff, with Musescore
		// auto-placing the string/fret.
	}
	  
	function addNewForcedToString(measures, notesToWrite, pitch, string, fret, cursor) {
		console.log("In funct addNewForcedToString");
		
		cursor.setDuration(1, 4);
		notesToWrite = measures * 4; // assuming 4/4 time sig.
		var oNote = newElement(Element.NOTE);
		
		console.log("oNote string: ",oNote.string, " | pitch: ", oNote.pitch);
		//console.log("oNote pitch: ",oNote.pitch);
		
		cursor.rewind(Cursor.SELECTION_START); //<-- I am presuming we have selected a measure
		if (cursor.element.type === Element.CHORD) { //<-- am presuming the cursor is sitting on a chord element in score.
			var chord = cursor.element;
			var notes = cursor.element.notes;
			var numNotes = notes.length;
			console.log("# Notes in Chord:", numNotes);
			var oNote = newElement(Element.NOTE);
			oNote.string = string;
			oNote.fret = fret;
			oNote.pitch = pitch;
			console.log("oNote string: ", oNote.string, " | fret: ", oNote.fret, " | pitch: ", oNote.pitch);
			curScore.startCmd();
			chord.add(oNote);
			curScore.endCmd();
		}
		else {
			console.log("Cursor not sitting on a chord");
		}
		// RESULT: Works. You *must* set all three parms of pitch, string and fret for it to work.
		// And in doing so they must be compatable or else Musescore will just use pitch and
		// set string and fret on it's own. So meaning, string's opening tuning + fret number
		// must = the midi pitch you set.
		
	  }

	function translateFret(oNote) {
		//    PURPOSE: Takes a note object and translates it to mountain dulcimer 
		// diatonic+ fret number.
		//    RETURNS: An object with three properties: A property value holding the
		// translated fret number, a bool value that is TRUE if the fret number 
		// needs to be appended with a plus (+) symbol. (E.g., the 1.5 fret in 
		// dulcimer terms). A property holding the new pitch value that matchs the
		// new string/fret number combo.
		console.log("In funct translateFret");
		
		var iPitch = oNote.pitch;
		var iString = oNote.string;
		var iFret = oNote.fret;
		
		//below is kludge for testing/learning for now
		if (iFret >= 3) {
			oDulciFret.fret = iFret - 2;
			oDulciFret.pitch = iPitch - 2;
			oDulciFret.addPlus = false;
		}
		else {
			console.log("fret number too low");
			return
		}
	}
	  
	  
	function modTABnotes(oCursor) {
		//    Assumes: One or measures have been selected. There is at least one chord in the selection.
		
		console.log("In funct modTABnotes");

		var iNotePitch = 0;
		var iNoteString = 0;
		var iNoteFret = 0;
		var oNote = newElement(Element.NOTE);
		
		oCursor.rewind(Cursor.SELECTION_START);
		if (oCursor.element.type === Element.CHORD) {
			var oChord = oCursor.element;
			var oNotesArray = oCursor.element.notes;
			var iNumOfNotes = oNotesArray.length;
			console.log("# Notes in Chord:", iNumOfNotes);

			curScore.startCmd();
			for (var i=0; i<iNumOfNotes; i++) {
				iNotePitch = oNotesArray[i].pitch;
				iNoteString = oNotesArray[i].string;
				iNoteFret = oNotesArray[i].fret;
				console.log("*before* -> FOR NOTE ", i, " --> iNotePitch: ", iNotePitch, " | iNoteString: ", iNoteString, " | iNoteFret: ", iNoteFret);
				translateFret(oNotesArray[i]);
				oNotesArray[i].pitch = oDulciFret.pitch;
				oNotesArray[i].fret = oDulciFret.fret;
				iNotePitch = oNotesArray[i].pitch;
				iNoteString = oNotesArray[i].string;
				iNoteFret = oNotesArray[i].fret;
				console.log("*after* -> iNotePitch: ", iNotePitch, " | iNoteString: ", iNoteString, " | iNoteFret: ", iNoteFret);
			}
			curScore.endCmd();
		}
		else {
			console.log("Cursor not sitting on a chord");
		}
		// RESULT: This works.
		  
	}
	  

	onRun: {
			var TABstaff = 0;
			var TABtrack = 0;
			var numNotes = 0;
			var chordNotes;
			var endTick = 0;

			var cursor = curScore.newCursor()

			endTick = curScore.lastSegment.tick + 1;
			console.log("Length of Score in Ticks: ", endTick);

			cursor.staffIdx = TABstaff;
			cursor.track = TABtrack;
			cursor.rewind(Cursor.SCORE_START);

			//   Just add some notes to the TAB staff.
			//addNewNotes(1, 4, 62, cursor); // <-- This works fine.
			//addNewForcedToString(1, 1, 62, 1, 5, cursor); //<-- This now works.
			modTABnotes(cursor);
				
			Qt.quit();

	} //END OnRun


} // END Musescore

