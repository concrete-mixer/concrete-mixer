/*----------------------------------------------------------------------------
    Concrète Mixer - an ambient sound jukebox for the Raspberry Pi

    Copyright (c) 2014-2016 Stuart McDonald  All rights reserved.
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

public class FxFeedback extends Fx {
    LFO lfo;
    FilterBasic filter;
    float filterBaseFreq;
    "LPF" => string filterType;

    chooser.getInt(1, 2) => int choice;

    <<< "fxFeedback:" >>>;

    if ( choice == 1 ) {
        LPF lpf @=> filter;

        chooser.getInt(2000, 8000) => filterBaseFreq;
    }

    if ( choice == 2 ) {
        "HPF" => string filterType;
        HPF hpf @=> filter;
        chooser.getInt(500, 2000) => filterBaseFreq;
    }

    Delay delay;
    input => filter => delay => Gain g => Dyno dyn => Gain g2 => output;
    input => output;
    dyn.limit();
    dyn => filter;
    1.1 => g.gain;
    0.50 => g2.gain;
    60.0 / Config.bpm * 1000.0 => float beatInterval; // BI = beat interval in ms;
    // 0 => filter.Q;
    0.05 => float lfoFreq;
    filterBaseFreq / 2 => float filterAmount;

    // select a few interesting delay values
    Time.bpmIntervalsMedium @=> float mediumIntervals[];
    Time.bpmIntervalsShort @=> float shortIntervals[];
    Time.bpmIntervalsLong @=> float longIntervals[];


    getLength( shortIntervals ) * 1000 => float delayLength;
    1 / getLength( longIntervals ) => lfoFreq;

    <<< "* Filter type: HPF" >>>;
    <<< "* filterBaseFreq", filterBaseFreq >>>;
    <<< "* filterAmount", filterAmount >>>;
    <<< "* delayLength", delayLength >>>;
    <<< "* lfoFreq", lfoFreq >>>;

    fun string idString() {
        return "FxFeedback";
    }

    fun float getLength( float intervals[]) {
        chooser.getInt( 0, intervals.cap() - 1 ) => int targetDelay;
        return intervals[ targetDelay ];
    }

    fun void initialise() {
        1 => active;

        delayLength::ms => delay.max;
        delayLength::ms => delay.delay;
        spork ~ activity();
    }

    fun void activity() {
        while ( active ) {
            lfo.osc( lfoFreq, filterAmount, "sine" ) => float freqDelta;
            filterBaseFreq + freqDelta => filter.freq;
            50::ms => now;
        }

        input =< filter =< delay =< dyn => output;
        dyn =< delay;
    }
}
