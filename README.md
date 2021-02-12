# mscore-plugin-SMN2DiatonicTab
A Musescore plugin that reads a standard music notation staff and writes it out to Mountain Dulcimer diatonic TAB

To Install: Copy the .qml file into your musesdcore 'plugins' directory, then in Musescore enable it in the Plugins menu.

TO USE --
   1. Be sure there is a TAB staff directly below the SMN staff you wish to use as the source. Be sure this TAB staff was created using one of the Mountain Dulcimer (Tablature) instruments so that the number of strings and open string tuning is corrent. IF you are making TAB for a different tuning, use the TAB staff properties to set the open string pitches to match your tuning.
   
   2. Select one, several, or all, the measures of the SMN staff you wish to make TAB for. Initially you would select all measures. But if you later make some minor changes to only a few measures you can select only those so that the TAB is updated only for those modified measures.
   
   3. Run the plugin from Musescore's plugin menu.
   
LIMITATIONS --

   a. This is my first significant plugin and it was a steep learning curve, so expect bugs and surprises.
   
   b. This release only handles the notes on the SMN staff - at present it does not put in ties, slurs or any other articulations. I'm expecting those to be a challenge for me to work out; but am hoping to get there for a future release. So you will need to do some fixups after running the plugin. My hope tho, is that this at least does most of the grunt-work of getting the fret-numbers onto a TAB staff for you.
   
   c. The mountain dulcimer half-fret symbols, those "+" symbols, will almost always need fixing up. Musescore, of course, cannot have a non-integer fret #, so the half-frets have to be added as Staff Text. There isn't any way to lock a Staff Text item to a specific note's position on the staff. So you will find that the positioning goes awary whenever you change formatting from the TAB staff's built in defaults. I am going to keep looking at ways to make this work better.
   
   d. No support for a capo as yet.
   
ISSUES -- As you find bugs and issues, please go ahead and open an issue item here on github.
