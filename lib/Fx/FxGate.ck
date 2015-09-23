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

public class FxGate extends Fx {
    LFO lfo;
    Gain g;
    float lfoBaseFreq;
    float amount;
    float lfoOscFreq;
    float lfoOscAmount;

    fun string idString() { return "FxGate"; }

    fun void initialise() {
        chooser.getFloat( 0.5, 3 ) => lfoBaseFreq;
        chooser.getFloat( 0.25, 1.5 ) => lfoOscAmount;

        -0.99 => amount;
        chooser.getFloat( 0.01, 0.05 ) => lfoOscFreq;
        input => g => output;
        <<< "   FxGate: sine at", lfoBaseFreq, "Hz", "lfo amount:", amount >>>;
        <<< "   Freq", lfoBaseFreq::second / Control.srate, 1 / lfoBaseFreq >>>;
        spork ~ activity();
    }

    fun void activity() {
        while ( true ) {
            lfo.osc( lfoOscFreq, lfoOscAmount, "sine" ) => float freqDelta;
            lfoBaseFreq + freqDelta => float lfoFreqFinal;
            lfo.osc( lfoFreqFinal, amount, "sine" ) => float gainDelta;
            0.5 + gainDelta => g.gain;
            1::ms => now;
        }
    }

    fun void volCheck() {
        while ( true ) {
            <<< g.gain() >>>;
            1::second => now;
        }
    }
}
