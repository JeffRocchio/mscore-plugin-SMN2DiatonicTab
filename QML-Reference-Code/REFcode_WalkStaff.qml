//=============================================================================
//  MuseScore Plugin
//
//  This plugin is a skeleton model for walking a staff
//  
//=============================================================================


//------------------------------------------------------------------------------
//  1.0: 04/10/2021 | Created
//------------------------------------------------------------------------------


import QtQuick 2.0
import QtQuick.Dialogs 1.1
import MuseScore 3.0

MuseScore {
	version:  "1.2"
	description: "Walk a staff"
	menuPath: "Plugins.TEST.Walk Staff"

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
		"Nothing Selected - please select 1 or more measures and try again.",
					//	2:
		" ",
					//	3:
		" ",
					//	4:
		"Unrecognized element on staff. Don't know how to handle it.",
					//	5:
		"Selection appears to be invalid. Please clear your selection and try again.",
					//	6:
		" ",
					//	7:
		" ",
					//	8:
		"ERROR: Infinite Loop in walkStaff()"
		]
		
		function getError() { return bError; }
		
		function clearError() { 
			bError = false; 
			return;
		}
		
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

	QtObject { // oSelection
		id: oSelection
		property int iUsrSelectStartTick: 0;
		property int iUsrSelectEndTick: 0;
		
		function setRangeTicks(oCursor) {
			//	PURPOSE: Given a user's range selection, decode
			//the starting and ending cursor tick values
			
			var bDEBUG = true;
			//bDEBUG = false;
			
			if(bDEBUG) oDebug.fnEntry(setRangeTicks.name);
			
			oCursor.rewind(Cursor.SELECTION_START);
			oSelection.iUsrSelectStartTick = oCursor.tick;
			oCursor.rewind(Cursor.SELECTION_END);
			if (oCursor.tick === 0) {
					//	This happens when the selection includes
					//the last measure of the score. rewind(SELECTION_END) goes 
					//1 tick beyond the last segment (where there's none) 
					//and sets tick=0
				if (bDEBUG) {
					console.log(" **** | We have the Last Measure Selection problem | ****");
					console.log("---- ---- Tick of Last Segment in Score <", curScore.lastSegment.tick, ">, which is a <", curScore.lastSegment.segmentType, ">");
				}
				oSelection.iUsrSelectEndTick = curScore.lastSegment.tick + 1;
			} else {
				oSelection.iUsrSelectEndTick = oCursor.tick;
			}
			if (bDEBUG) console.log("    ---- Selection Start Tick <", oSelection.iUsrSelectStartTick, "> ,  EndTick <", oSelection.iUsrSelectEndTick, ">");

			if(bDEBUG) oDebug.fnExit(setRangeTicks.name);
			
		} // end oSelection.setRangeTicks()
		
	} // end QtObject oSelection
	
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
		//if it appears that everything is valid.
		//   RETURNS:
		//		1.	true if all is well, false if not. And if true:
		//		2.	If false, the oUserMessage object will contain
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
		
		if(bDEBUG) oDebug.fnExit(assessValidity.name);
		return true;
		
	} // end assessValidity()
	
	function walkStaff(oCursor) {
		//	PURPOSE: Walk through the staff
		//	ASSUMES: 
		//		1.	We have successfully passed the assessValidity() tests.
		//		2.	The oSelection object has been initilized with the 
		//			user's selection range start and end tick values.

		var bDEBUG = true;
		//bDEBUG = false;
		
		if(bDEBUG) oDebug.fnEntry(walkStaff.name);
		
		if (bDEBUG)  console.log("---- | Entering staff-walking while loop ---->>")
		oCursor.rewind(Cursor.SELECTION_START);
		var iWatchDog = 20;
		while (oCursor.segment && oCursor.tick < oSelection.iUsrSelectEndTick) {
			if (bDEBUG)  console.log("---- ---- Next element Type on staff <", oCursor.staffIdx, "> at Tick <", oCursor.tick, "> is a <", oCursor.element.name, "> | (Selection Last Tick is <", oSelection.iUsrSelectEndTick, ">)");
			oCursor.next();
			if(oCursor.segment) {
				if (bDEBUG)  console.log("---- ---- AFTER cursor.next() call: Next segment on Staff <", oCursor.staffIdx, "> at Tick <", oCursor.tick, "> is a <", oCursor.segment.segmentType, "> | (Selection Last Tick is <", oSelection.iUsrSelectEndTick, ">)\n");
			} else {
				if (bDEBUG)  console.log("---- ---- AFTER cursor.next() call: Next segment is NULL at tick <", oCursor.tick, "> | (Selection Last Tick is <", oSelection.iUsrSelectEndTick, ">)\n");
			}
			iWatchDog--;
			if(iWatchDog == 0) {
				console.log("**** **********************************************************");
				console.log("**** ERROR: WatchDog exceeded in while loop");
				console.log("**** Cursor is hung at Tick <", oCursor.tick, ">");
				console.log("**** Selection EndTick is <", oSelection.iUsrSelectEndTick, ">");
				console.log("**** **********************************************************");
				oUserMessage.setError(8);
				break;
			}
		} // end staff-walking loop
		//if (bDEBUG)  console.log("---- | Walking Completed. Cursor sitting at tick <", oCursor.tick, "> | (Selection Last Tick is <", oSelection.iUsrSelectEndTick, ">)\n");

		if(bDEBUG) oDebug.fnExit(walkStaff.name);
	} // end of walkStaff()
	

//==== PLUGIN RUN-TIME ENTRY POINT =============================================

	onRun: {
		console.log("********** RUNNING **********");

		var oCursor = curScore.newCursor()
		
					//	Check that our selections looks valid.
					//	Also note that the assessValidity() function will
					//initilize the oSelection object as well.
		if (!assessValidity (oCursor)) {
			oUserMessage.popupError();
		}
					//	All looks OK, so let's walk the staff.
		else { 
			oSelection.setRangeTicks(oCursor); // Set range start/end ticks.
			walkStaff(oCursor); // Go walk the staff.
			if (oUserMessage.getError()) oUserMessage.popupError(); // inform user if lingering errors.
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

