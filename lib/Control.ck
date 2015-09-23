/*----------------------------------------------------------------------------
    Concrète Mixer - an ambient sound jukebox for the Raspberry Pi

    Copyright (c) 2014 Stuart McDonald  All rights reserved.
        https://github.com/concrete-mixer/concrete-mixer

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
    U.S.A.
-----------------------------------------------------------------------------*/

/*
    Increase the size of the array to get more channels
    Due to Kassen, see http://wiki.cs.princeton.edu/index.php/buses
*/

public class Control {
    static Gain @ leftOut;
    static Gain @ rightOut;
    static Gain @ fxIn;
    static int sampleActive[];
    static float bpm;
    static float bpmInterval;
    static float bpmIntervalsShort[];
    static float bpmIntervalsMedium[];
    static float bpmIntervalsLong[];
    static dur beatDur;
    static dur barDur;
    static int beatLength;
    static int barLength;
    static int srate;
    static int record;
    static int rpi;

    static OscSend @ oscSend;

    fun static void changeSampleActive( int index, int setting ) {
        <<< "Control.changeSampleActive - index:", index, index - 1, "setting:", setting >>>;
        setting => sampleActive[ index - 1 ];
    }

    fun static int getSampleActive( int index ) {
        return sampleActive[ index - 1 ];
    }
}

new Gain @=> Control.leftOut;
new Gain @=> Control.rightOut;
new Gain @=> Control.fxIn;

Dyno dynoL => dac.left;
Dyno dynoR => dac.right;

// Set config values
Std.atof( me.arg(0) ) => Control.bpm;
Std.atoi( me.arg(1) ) => Control.srate;
Std.atoi( me.arg(2) ) => Control.record;
Std.atoi( me.arg(3) ) => Control.rpi;

WvOut2 wv;

if ( Control.record ) {
    "concrete-mixer-output" => wv.autoPrefix;

    // this is the output file name
    "special:auto" => wv.wavFilename;

    Control.fxIn => blackhole;
    dac => wv => blackhole;
}

dynoL.limit();
dynoR.limit();

Control.leftOut => dynoL; // left 'dry' out
Control.rightOut => dynoR; // right 'dry' out

0.3 => Control.fxIn.gain;

[ 0, 0 ] @=> Control.sampleActive;

new OscSend @=> Control.oscSend;
Control.oscSend.setHost("localhost", 3141);

( 60 / Control.bpm ) => float bpmInterval;
bpmInterval => Control.bpmInterval;

[
     bpmInterval / 8,
     bpmInterval / 6,
     bpmInterval / 5 * 2,
     bpmInterval / 4, // quaver
     bpmInterval / 3,
     bpmInterval / 2,
     bpmInterval / 3 * 2,
     bpmInterval / 4 * 3, // 3 quavers
     bpmInterval * ( 3.0 / 2.0 ),
     bpmInterval * 2,
     bpmInterval * ( 5.0 / 2.0 )
] @=> Control.bpmIntervalsShort;

[
    bpmInterval / 4,
    bpmInterval / 3,
    bpmInterval / 2,
    bpmInterval / 4 * 3, // 3 quavers
    bpmInterval,
    bpmInterval * ( 4.0 / 3.0 ),
    bpmInterval * 1.5,
    bpmInterval * ( 5.0 / 3.0 ),
    bpmInterval * 2.0,
    bpmInterval * 2.5,
    bpmInterval * 3.0,
    bpmInterval * 4.0,
    bpmInterval * 5.0,
    bpmInterval * 5.0,
    bpmInterval * 8.0
] @=> Control.bpmIntervalsMedium;

[
     bpmInterval * 4,     // 1 'bar'
     bpmInterval * 4 * 2, // 2 'bars'
     bpmInterval * 4 * 2.5, // 2 'bars'
     bpmInterval * 4 * 3, // 3 'bars'
     bpmInterval * 14,    // 3.5 'bars'
     bpmInterval * 4 * 4, // 4 'bars'
     bpmInterval * 3 * 6, // 4.5
     bpmInterval * 4 * 5, // 5
     bpmInterval * 4 * 6, // 6
     bpmInterval * 4 * 8  // 8
] @=> Control.bpmIntervalsLong;

bpmInterval::second => Control.beatDur;
Control.beatDur * 4 => Control.barDur;
( bpmInterval * Control.srate ) $ int => Control.beatLength;
( Control.beatLength * 4 ) => Control.barLength;

null @=> wv;

while ( true ) {
    10::second => now;
}
