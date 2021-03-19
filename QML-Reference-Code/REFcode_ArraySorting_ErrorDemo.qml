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
	description: qsTr("Error: Won't call sort using unshift vs push")
	menuPath: "Plugins.DEV - Ties"

	onRun: {

					//	Just show that basic sort works fine.
		var fruits = ["Banana", "Orange", "Apple", "Mango"];
		fruits.sort();
		console.log("\n\n---- Fruits Array Listing After Sorting -->>");
		console.log("---- array size <", fruits.length, ">");
		for(var i=0; i<fruits.length; i++) {
			console.log("---- ---- Element Index <", i, "> Fruit <", fruits[i], ">");
		}
		console.log("\n");
		
					//	Now, let's declare an array of objects and show that
					//it also sorts fine when each Element is contained in the
					//initial declaration.
		var fruitsAndTicks = [
			{fruit: "Banana", tick: 0},
			{fruit: "Orange", tick: 1},
			{fruit: "Apple", tick: 2},
			{fruit: "Mango", tick: 3}
		];
		fruitsAndTicks.sort(function(a,b) {
			console.log("*** In fruitsAndTicks sort compare() ***");
			return a.tick - b.tick; 
			});
		console.log("\n\n---- fruitsAndTicks Array Listing After Sorting on **Tick** -->>");
		console.log("---- array size <", fruitsAndTicks.length, ">");
		for(var i=0; i<fruitsAndTicks.length; i++) {
			console.log("---- ---- Element Index <", i, "> Fruit <", fruitsAndTicks[i].fruit, ">  Tick <", fruitsAndTicks[i].tick, ">");
		}
		console.log("\n");

		//	Now we'll build an array of objects using the 'push' method
		//and show that it will properly call the sort function.
		var pushMe = [];
		pushMe.push( { col1: "Robert is", col2: 35});
		pushMe.push( { col1: "Jane is", col2: 37});
		pushMe.push( { col1: "Joe is", col2: 48});
		pushMe.push( { col1: "Niki is", col2: 20});
		pushMe.push( { col1: "Johnny", col2: 35});
		pushMe.sort(function(a,b) {
			console.log("*** In pushMe sort compare() ***");
			return a.col2 - b.col2; 
		});
		console.log("\n\n---- pushMe Array Listing after sort on Age (col2) -->>");
		console.log("---- array size <", pushMe.length, ">");
		for(var i=0; i<pushMe.length; i++) {
			console.log("---- ---- Element Index <", i, "> Person <", pushMe[i].col1, ">  Age <", pushMe[i].col2, ">");
		}
		console.log("\n");
		
		//	Ok, now let's build an array of objects using the 'unshift' function
		//and show that it then refuses to call the sort function.
		var unshiftMe = [];
		for(var i=0; i<4; i++) {
			unshiftMe.unshift({
				col1: i, 
				col2: i+35
				});
		}
		unshiftMe.sort(function(a,b) {
			console.log("*** In unshiftMe sort compare() ***");
			return a.col2 - b.col2; 
		});
		console.log("---- unshiftMe Array Listing after attempting a sort on col2 (Age)-->>");
		console.log("---- array size <", fruitsAndTicks.length, ">");
		for(var i=0; i<unshiftMe.length; i++) {
			console.log("---- ---- Element Index <", i, "> Person <", unshiftMe[i].col1, ">  Age <", unshiftMe[i].col2, ">");
		}
		console.log("\n---- This run didn't sort, right? Not calls made to the soft's compare function, right?");
		console.log("\n");
		
		//	FINALLY, let's build that exact same array of objects, but this time
		//using the 'push' method; and show that it then does call the sort function.
		var unshiftMe = [];
		for(var i=0; i<4; i++) {
			unshiftMe.push({
				col1: i, 
				col2: i+35
			});
		}
		unshiftMe.sort(function(a,b) {
			console.log("*** In unshiftMe sort compare() after building array with 'push' method ***");
			return a.col2 - b.col2; 
		});
		console.log("---- unshiftMe Array Listing after sorting on col2 (Age)-->>");
		console.log("---- array size <", fruitsAndTicks.length, ">");
		for(var i=0; i<unshiftMe.length; i++) {
			console.log("---- ---- Element Index <", i, "> Person <", unshiftMe[i].col1, ">  Age <", unshiftMe[i].col2, ">");
		}
		console.log("\n---- This run *did* sort, correct?");
		console.log("\n");
		
		
	console.log("\n\n--- Plugin Exiting ---");
	Qt.quit();
	} // end onRun
	
	
} // end Musescore
