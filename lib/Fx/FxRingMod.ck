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

public class FxRingMod extends Fx {
    Chooser c;
    SinOsc sine => Gain ring;
    3 => ring.op; // as per http://chuck.cs.princeton.edu/doc/examples/basic/ring.ck

    float freq, factor;

    input => ring => output;

    fun string idString() {
        return "FxRingMod";
    }

    fun void initialise() {
        c.getFloat( 220, 550 ) => freq => sine.freq;

        spork ~ activity();
    }

    fun void activity() {
        while ( active ) {
            shiftFreq();
            <<< "sine.freq now", sine.freq() >>>;
            c.getInt( 4, 16 ) * Control.beatDur => now;
        }

        input =< ring =< output;
        sine =< ring;
    }

    fun void shiftFreq() {
        Control.beatDur * 1 => dur shiftTime;
        sine.freq() => float oldFreq;
        getFreq() => float newFreq;

        // first, determine new shift position
        float shiftAmountIncrement, difference;
        dur shiftTimeIncrement;

        shiftTime / 100 => shiftTimeIncrement;

        if ( oldFreq < newFreq ) {
            ( newFreq - oldFreq ) => difference;
        }
        else {
            - ( oldFreq - newFreq ) => difference;
        }

        difference / 100 => shiftAmountIncrement;

        while ( shiftTime > 0::second ) {
            sine.freq() => float currshift;
            currshift + shiftAmountIncrement => sine.freq;
            shiftTimeIncrement => now;
            shiftTimeIncrement -=> shiftTime;
        }

        <<< "oldfreq", oldFreq, "newfreq", newFreq, "shiftAmountIncrement", shiftAmountIncrement, "actual freq", freq >>>;
    }

    fun float getFreq() {
        [ 0.25, 0.5, 1.0, 2.0, 4.0, 8.0, 12.0 ] @=> float factors[];

        c.getInt( 0, factors.cap() -1 ) => int choice;

        if ( factors[ choice ] == factor ) {
            return getFreq();
        }
        else {
            factors[ choice ] => factor;
            return factor * freq;
        }
    }
}
