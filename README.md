# plantmotion_Vis 
#Biomodd[BRG13]


Version 0.7


Plantmotion visualization for Processing. 

This sketch is written for the plant interaction installation as part of Biomodd[BRG13].
Running the sketch and pointing a webcam to plants, this visualization detects plant motion and hides or reveals (depending on the settings) cells within a matrix.

Motion tracking is based on the principle of down sampling and comparing previous vs current values of Hue and Brightness within the HSB palette. 

Hue and Brightness of a cell are compared with the previous frame Hue and Brightness of that cell.

A target rectangle follows the 'center of gravity' of all 'moving' cells. The associated x-y values of the rectangle could be used as output values for further interaction.
\
\
The following settings and controls are available:
\
'Threshold' controls the sensitivity of cell comparison. Ie. a high sensitivity means a low difference values between H  and B.\
\
\
Threshold:..................cursor LEFT/RIGHT\
Cell size:..................cursor UP/DN\
Matrix on/off:..............M\
targetRect..................T\
Video clear screen on/off:..C\
\
\
S:   save frame\
M:   cell matrix on/off\
C:   solid background on/off\
T:   target rectangle on/off\
U:   User interface/help screen\
I:   inverter on/off. Active cell visibility\
\
\
cursor keys:\
UP/DOWN    : change cell size. Minimum = 4px\
LEFT/RIGHT : change threshold \
\
\
The .ttf files are the fonts needed for display text output and need to be placed in the same folder location as the .pde file. At this time there is no text interaction yet but a sample placeholder.
The sketch should work with almost any regular webcam. It may be necessary to adjust the webcam settings in order to gain a good contrast between the plant/leaves and the background.


