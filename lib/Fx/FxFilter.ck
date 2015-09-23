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

public class FxFilter extends Fx {
    FilterBasic filter;
    LFO lfo;
    string oscType;
    float amount, lfoFreq, baseFilterFreq, Q;

    fun string idString() { return "FxFilter"; }

    fun void initialise() {
        chooser.getInt( 1, 2 ) => int typeChoice;

        // baseFilterFreq is base frequency for filter
        // may or may not end up being oscillated

        string filterChosen;

        chooser.getFloat( 1, 5 ) => Q;

        if ( typeChoice == 1 ) {
            LPF lpf @=> filter;

            // for lpf, we want a lowish base freq
            "LPF" => filterChosen;
            chooser.getFloat( 700, 1500 ) => baseFilterFreq;
        }

        if ( typeChoice == 2 ) {
            HPF hpf @=> filter;
            "HPF" => filterChosen;
            chooser.getFloat( 1000, 2000 ) => baseFilterFreq;
        }

        input => filter => output;

        // set baseFilterFreq

        // set Q between 1 and 5
        Q => filter.Q;

        // determine whether to oscillate (mostly yes)
        if ( chooser.takeAction( 1 ) ) {
            // as a rule amount should be less than basefreq over 3
            chooser.getFloat( baseFilterFreq / 3, baseFilterFreq / 3 + baseFilterFreq / 6 ) => amount;

            // going with sine only for oscillation - square a bit annoying
            // and s/h a bit old fash
            "sine" => oscType;

            Control.bpmIntervalsLong @=> float lfoFreqs[];
            1 / lfoFreqs[ chooser.getInt( 0, lfoFreqs.cap() - 1 ) ] => lfoFreq;

            // sample hold is better when its faster...
            if ( oscType != "sine" ) {
                lfoFreq * 20 => lfoFreq;
            }

            spork ~ activity();
        }
        <<< "   FxFilter:", filterChosen, "at", baseFilterFreq, "Hz", "q:", Q, "lfoFreq:", lfoFreq, "lfo amount:", amount >>>;
    }

    fun void activity() {
        while ( true ) {
            lfo.osc( lfoFreq, amount, oscType ) => float freqDelta;
            baseFilterFreq + freqDelta => filter.freq;
            100::ms => now;
        }
    }
}
