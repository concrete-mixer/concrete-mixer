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

public class FxHarmonicDelay extends Fx {
    Delay delay;
    Chooser c;
    LFO lfo;
    input => delay => Gain g => output;
    Gain feedback;
    delay => feedback;
    feedback => input;
    0.8 => g.gain;
    c.getInt( 0, 1 ) => int doOscFeedback;
    ( 1 / c.getIntervalLong() ) => float oscFeedbackFreq;

    ( Control.bpm / 60 ) * 1000.0 => float beatInterval; // BI = beat interval in ms;

    [ 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 37 ] @=> int midiNotes[];

    c.getInt( 0, midiNotes.cap() - 1 ) => int choice;
    midiNotes[ choice ] => Std.mtof => float baseFreq;

    1 / baseFreq => baseFreq;

    // select a few interesting delay values
    Control.bpmIntervalsShort @=> float delayIntervals[];

    [ 1.0, 1.333, 1.5, 2.0, 2.666, 2.5, 3.0, 4.0, 5.0, 6.0 ] @=> float factors[];

    baseFreq => float delayAmount;

    fun string idString() {
        return "FxHarmonicDelay";
    }

    fun void initialise() {
        1 => active;

        0.5 => float delayMax;
        delayAmount => float delayLength;

        0.9 => float delayMix;

        delayMax::second => delay.max;
        delayLength::second => delay.delay;
        delayMix => feedback.gain;
        spork ~ activity();
    }

    fun void activity() {
        // set a delay frequency and a period for that delay to be in place
        // using the factors array

        if ( doOscFeedback ) {
            spork ~ oscFeedback();
        }

        while ( active ) {
            factors[ c.getInt(0, factors.cap() - 1) ] => float choice;
            ( beatInterval * choice )::ms => now;
            factors[ c.getInt(0, factors.cap() - 1) ] => choice;
            baseFreq * choice => float amount;
            amount::second => delay.delay;
        }

        input =< delay =< output;
        delay =< feedback =< input;
    }

    fun void oscFeedback() {
        while ( active ) {
            lfo.osc( oscFeedbackFreq, 0.25, "sine" ) + 0.7 => feedback.gain;
            10::ms => now;
        }
    }
}
