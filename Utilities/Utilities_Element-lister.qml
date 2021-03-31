//=============================================================================
//  MuseScore
//  Music Composition & Notation
//
//  Copyright (C) 2020 Jeffrey Rocchio
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License version 2
//  as published by the Free Software Foundation and appearing in
//  the file LICENCE.GPL
//=============================================================================

import MuseScore 3.0

MuseScore {
      version:  "0.0"
      description: "This plugin lists element attributes"
      menuPath: "Plugins.ElementList"

	onRun: {

		var e; // To store an element object
		var parentElement;
		var staff;
		var scoreElement // = e.ScoreElement;
		var oChord // = cursor.element if cursor.element.type === Element.CHORD
		var oNotesArray;
		var iNumOfNotes;
		var endTick;
		var numberOfParts = curScore.parts.length;
		var numberOfInstruments;
		var numOfStrings;
		

		console.log("Running....");
		
		console.log(" ");
		console.log("Number of Staves in Score: ", curScore.nstaves);
		console.log("Number of Parts in Score: ", curScore.parts.length);
		console.log(" ");
		
		if (numberOfParts > 0) {
			// Inspect Parts
			for (var i = 0; i < curScore.parts.length; i++) {
				console.log(" ");
				console.log("--> Part [", i, "]: ", curScore.parts[i].partName);
				console.log("------: startTrack " , curScore.parts[i].startTrack);
				console.log("------:   endTrack " , curScore.parts[i].endTrack);
				console.log("------: hasTabStaff " ,curScore.parts[i].hasTabStaff);
				console.log("------: hasPitchedStaff " ,curScore.parts[i].hasPitchedStaff);
				console.log("------: Number of Instruments in Part " , curScore.parts[i].instruments.length);
				numberOfInstruments = curScore.parts[i].instruments.length;
				if (numberOfInstruments > 0) {
					console.log(" ");
					for (var k = 0; k < numberOfInstruments; k++) {
						console.log(" ");
						console.log("====|| Instrument [", k, "] shortName: ", curScore.parts[i].instruments[k].shortName);
						console.log("====|| Instrument [", k, "] longName: ", curScore.parts[i].instruments[k].longName);
						console.log("====|| Instrument [", k, "] # of Strings: ", curScore.parts[i].instruments[k].stringData.strings.length);
						numOfStrings = curScore.parts[i].instruments[k].stringData.strings.length;
						for (var j = 0; j < numOfStrings; j++) {
							console.log("        >> String [", j, "] Pitch: ", curScore.parts[i].instruments[k].stringData.strings[j].pitch); 
							
						} // end strings listing loop
					} // end instrument listing loop
				} // end numberOfInstruments IF smt
			} // end numberOfParts listing loop
		} // end numberOfParts IF stmt
		
		var cursor = curScore.newCursor();
		cursor.voice    = 0;
		cursor.staffIdx = 0;

		cursor.rewind(Cursor.SELECTION_START);
		if (!cursor.segment) { // no selection in score.
			console.log("no selection, using whole score");
			cursor.rewind(Cursor.SCORE_START);
		} else {
			cursor.rewind(Cursor.SELECTION_END);
			if (cursor.tick === 0) {
				//   (This happens when the selection includes
				//the last measure of the score. rewind(2) goes 
				//behind the last segment (where there's none) 
				//and sets tick=0)
				endTick = curScore.lastSegment.tick + 1;
			} else {
				endTick = cursor.tick;
			}
		}

		cursor.filter =  Segment.All;
		cursor.rewind(Cursor.SELECTION_START);
		e = cursor.element;
		while (cursor.segment && cursor.tick < endTick) {
			e = cursor.element; // Let's get the base element at cursor.
			console.log(" ");
			console.log("Base Element Name: ", e.name, " | at  tick:", cursor.tick);

			console.log(" ");
			console.log("** What Can We Get From Just the cursor object? **");
			console.log("**| keySignature = ", cursor.keySignature);
			console.log("**| staffGenClef = ", cursor.staffGenClef);
			console.log("**| fontSize = ", cursor.fontSize);
			console.log(" ");
			
			//   I wish to do some inspections of what I can retrieive from a chord or note element.
			if (cursor.element.type === Element.CHORD) {
				console.log("We have a chord: ", e.name, " | at  tick:", cursor.tick);
				oChord = cursor.element;
				oNotesArray = oChord.notes;
				iNumOfNotes = oNotesArray.length;
				console.log("# Notes in Chord:", iNumOfNotes);
				for (var i=0; i<iNumOfNotes; i++) {
					console.log("--| Pitch ", oNotesArray[i].pitch);
					console.log("--| String ", oNotesArray[i].string);
					console.log("--| Fret ", oNotesArray[i].fret);
					console.log("--| position", oNotesArray[i].position);
					console.log("--| posX", oNotesArray[i].posX);
					console.log("--| posY", oNotesArray[i].posY);
					console.log(" ");
					
				} // end if for notes inspection
				
			} // end chord inspection IF stmt.
			
			staff = e.staff;
			console.log("Element object type:", staff.name, " | index: ", cursor.staffIdx, " | at  tick:", cursor.tick);
			console.log("--| Part this Staff Belongs To:", staff.part.partName);
			console.log("--| staffGenClef:", staff.staffGenClef);
			console.log("--| staffLines:", staff.staffLines);
			console.log("--| fretStrings:", staff.fretStrings);
			console.log("--| playbackVoice1,:", staff.playbackVoice1);
			console.log("--| playbackVoice2,:", staff.playbackVoice2);
			console.log("--| playbackVoice3,:", staff.playbackVoice3);
			console.log("--| playbackVoice4,:", staff.playbackVoice4);
			console.log("--| instrumentId:", staff.instrumentId);
			console.log(" =====\n");

			//parentElement = staff.parent;
			//console.log("Staff's parent:", parentElement.name, " | at  tick:", cursor.tick);
			//console.log(" =====\n");

			
			console.log("Root e type:", e.name, " | at  tick:", cursor.tick);
			console.log("--| staffLines:", e.staffLines);
			console.log("--| hasPitchedStaff:", e.hasPitchedStaff);
			console.log("--| instrumentId:", e.instrumentId);
			console.log("--| timesigNominal:", e.timesigNominal.numerator, "/", e.timesigNominal.denominator);
			console.log("--| actualNotes:", e.actualNotes);
			console.log("--| measureNumberMode:", e.measureNumberMode);
			console.log("--| role:", e.role);
			console.log("--| track:", e.track);
			console.log("--| fretStrings:", e.fretStrings);
			console.log("--| staffGenClef:", e.staffGenClef);
			console.log(" =====\n");

			parentElement = e.parent;
			console.log("Root e's parent:", parentElement.name, " | at  tick:", cursor.tick);
			console.log("----| staffLines:", parentElement.staffLines);
			console.log("----| hasPitchedStaff:", parentElement.hasPitchedStaff);
			console.log("----| instrumentId:", parentElement.instrumentId);
			console.log("----| actualNotes:", parentElement.actualNotes);
			console.log("----| measureNumberMode:", parentElement.measureNumberMode);
			console.log("----| role:", parentElement.role);
			console.log("----| track:", parentElement.track);
			console.log("----| fretStrings:", parentElement.fretStrings);
			console.log("----| staffGenClef:", parentElement.staffGenClef);

			console.log(" =====\n");
			parentElement = e.parent.parent;
			console.log("Root e's parent.parent:", parentElement.name, " | at  tick:", cursor.tick);
			console.log("------| staffLines:", parentElement.staffLines);
			console.log("------| hasPitchedStaff:", parentElement.hasPitchedStaff);
			console.log("------| instrumentId:", parentElement.instrumentId);
			console.log("------| timesigNominal:", parentElement.timesigNominal.numerator, "/", parentElement.timesigNominal.denominator);
			console.log("------| actualNotes:", parentElement.actualNotes);
			console.log("------| measureNumberMode:", parentElement.measureNumberMode);
			console.log("------| role:", parentElement.role);
			console.log("------| track:", parentElement.track);
			console.log("------| fretStrings:", parentElement.fretStrings);
			console.log("------| staffGenClef:", parentElement.staffGenClef);

			console.log(" =====");
			parentElement = e.parent.parent.parent;
			console.log("Root e's parent.parent.parent:", parentElement.name, " | at  tick:", cursor.tick);
			console.log("--------| staffLines:", parentElement.staffLines);
			console.log("--------| hasPitchedStaff:", parentElement.hasPitchedStaff);
			console.log("--------| instrumentId:", parentElement.instrumentId);
			console.log("--------| actualNotes:", parentElement.actualNotes);
			console.log("--------| measureNumberMode:", parentElement.measureNumberMode);
			console.log("--------| role:", parentElement.role);
			console.log("--------| track:", parentElement.track);
			console.log("--------| fretStrings:", parentElement.fretStrings);
			console.log("--------| staffGenClef:", parentElement.staffGenClef); 

			cursor.next();
		}

            Qt.quit();
            }
      }
