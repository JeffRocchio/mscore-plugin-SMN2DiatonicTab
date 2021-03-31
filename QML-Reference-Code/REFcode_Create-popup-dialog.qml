//=============================================================================
//  MuseScore
//  Music Composition & Notation
//
//  Color Melody-Line Notes Plugin
//
//  This plugin will make a naive attempt to color notes red to mark the
//  melody-line of the score. It simply assumes that the highest pitched
//  note is the melody note. To use it you do have to select one, or all,
//  of the measures on one staff. This is my first plugin so it certainly
//  is not sophisticated. While it is of use to me, my main goal here was
//  to gain some experience making a plugin. Please feel free to improve on
//  this.
//
//  Copyright (C) 2020 Jeffrey Rocchio
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License version 2
//  as published by the Free Software Foundation and appearing in
//  the file LICENCE.GPL
//=============================================================================

import QtQuick 2.2
import QtQuick.Layouts 1.2
import QtQuick.Controls 1.0
import QtQuick.Dialogs 1.1
import MuseScore 3.0

MuseScore {
	version: "1.0.0"
	description: qsTr("Testing popup message boxes")
	menuPath: "Plugins.Notes." + qsTr("Popup Message Box")

	property string red : "#aa0000"
	
	MessageDialog {
		id: messageDialog
		title: "May I have your attention please"
		text: "It's so cool that you are using Qt Quick."
		onAccepted: {
			console.log("And of course you could only agree.")
			Qt.quit()
		}
		Component.onCompleted: visible = true
	}
	
	

	onRun: {
		
		errorDialog.openErrorDialog(qsTranslate("QMessageBox", "No score open.\nThis plugin requires an open score to run.\n"));
		
		//var QMessageBox msgBox;
		//msgBox.setText("The document has been modified.");
		//msgBox.exec();		
/*
						// Determine if we have anything selected. If not, abort.
						//In this iteration I am requiring that the user make a
						//selection to avoid coloring an entire multi-part score
						//since I mostly use this function for complex scores.
		cursor.rewind(1)
		if (!cursor.segment) { 
						// no selection. Give a message then fall through to the
						//end, ending the plugin.
			console.log("No Selection. Select one, or all, measures to color.");

						//   Ok, we have something selected, color notes within
						//the selection.
		} else {
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
			cursor.rewind(1) //  Move cursor back to start of selection.
			while (cursor.segment && cursor.tick < endTick) {
				if (cursor.element.type === Element.CHORD) {
				notes = cursor.element.notes;
				numNotes = notes.length;
				//sText = newElement(Element.STAFF_TEXT);
				//sText.text = numNotes;
				//cursor.add(sText);
				colorNotes(notes);
				}
			cursor.next();  // Move to next segment.
			} // end while
		} // end top else stmt
*/
		console.log("Plugin Exiting - presumed successful.");
		Qt.quit();
	} // end onRun

	
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
	
	
	MessageDialog {
		id: messageDialog
		title: "May I have your attention please"
		text: "It's so cool that you are using Qt Quick."
		onAccepted: {
			console.log("And of course you could only agree.")
			Qt.quit()
		}
		Component.onCompleted: visible = true
	}
	
	
	
}
