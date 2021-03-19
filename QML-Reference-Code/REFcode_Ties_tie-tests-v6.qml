// This comes from this issue: https://musescore.org/en/node/293837



import QtQuick 2.0
import MuseScore 3.0

MuseScore {
    version:  "3.0"
    description: "This test plugin test note.tieXXX stuff."
    menuPath: "Plugins.Test Ties"

    onRun: {
        console.log("Hello Tie Walker");

        if (!curScore)
            Qt.quit();

        console.log("Score name=" + curScore.scoreName)

        for (var curStaff = 0; curStaff < curScore.nstaves; curStaff++) {
            walkOneStaff(curStaff);
        }

        Qt.quit();
    } // onRun

    function lookUpEnum(enumObject, value) {
        for (var key in enumObject) {
            if (enumObject[key] != null && enumObject[key] == value) {
                return key;
            }
        }
        return value;
    }

    function walkOneStaff(staffIdx) {
        var cursor = curScore.newCursor();
        console.log("Score.elementId=" + curScore.elementId)
        cursor.filter = -1
        cursor.voice = 0
        cursor.staffIdx = staffIdx
        cursor.rewind(Cursor.SCORE_START)
        console.log("###### START STAFF " + cursor.staffIdx + " ######")
        var chordNum = 0;       // Current chord number on staff
        while (cursor.segment) {
            var e = cursor.element;
            if (e) {
                console.log("Element type=" + lookUpEnum(Element, e.type))
                console.log("e=" + e)
                if (e.type == Element.CHORD) {
                    var chord = e;
                    var notes = e.notes;
                    for (var idx = 0; idx < notes.length; idx++) {
                        var note = notes[idx];
                        console.log("Note[" + idx + "] of ChordNum " + chordNum)
                        console.log("----note=" + note)
                        console.log("----note.parent=" + note.parent)
                        console.log("----note.firstTiedNote=" + note.firstTiedNote)
                        if (note == note.firstTiedNote)
                            console.log("firstTiedNote is pointing back at ME!")
                        console.log("----note.lastTiedNote=" + note.lastTiedNote)
                        if (note == note.lastTiedNote)
                            console.log("lastTiedNote is pointing back at ME!")
                        if (note.tieBack != null) {
                            var tieback = note.tieBack;
                            console.log("----note has a tieBack:")
                            console.log("--------tieback.startNote=" + tieback.startNote)
                            console.log("--------tieback.endNote=" + tieback.endNote)
                        }
                        else
                            console.log("----note does not have a tieBack.")
                        if (note.tieForward != null) {
                            var tieforward = note.tieForward;
                            console.log("----note has a tieForward:")
                            console.log("--------tieForward.startNote=" + tieforward.startNote)
                            console.log("--------tieForward.endNote=" + tieforward.endNote)
                        }
                        else
                            console.log("----note does not have a tieForward.")
                    } // Note loop
                    for (var gc = 0; gc < chord.graceNotes.length; gc++) {
                        var gchord = chord.graceNotes[gc];
                        for (var gn = 0; gn < gchord.notes.length; gn++) {
                            var gnote = gchord.notes[gn];
                        } // Grace note loop
                    }
                    chordNum++
                } // Chord processing
                else {
                }
            }
            //console.log("------------------")
            cursor.next();
        } // Segment walk loop
        console.log("^^^^^^ END STAFF " + cursor.staffIdx + " ^^^^^^");
    }
}
