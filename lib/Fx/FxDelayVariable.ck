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


public class FxDelayVariable extends Fx {
    DelayL delay;
    Fader fader;
    input => delay => output;
    Gain feedback;
    0.50 => feedback.gain;
    output => feedback;
    feedback => input;

    fun string idString() {
        return "FxDelayVariable";
    }

    fun void initialise() {
        1 => active;

        // set max based on largest value in Time.bpmIntervalsShort
        getMax() => delay.max;

        spork ~ activity();
    }

    // set delay.max based on largest value in Time.bpmIntervalsShort
    fun dur getMax() {
        Time.bpmIntervalsShort.size() - 1 => int max;
        return Time.bpmIntervalsShort[max]::second;
    }

    fun void activity() {
        while ( active ) {
            // set duration for delay
            getNextDur() => dur duration;

            duration => delay.delay;
            duration - 400::samp => dur mainDuration;

            // ALl things being equal we only need to duration => now
            // at this point, but randomly changing delay times means
            // there may be audible discontinuities (as in pops)
            // in the signal.
            //
            // To paper over these cracks we fade the signal around
            // the discontinuities

            // fade in
            fader.fadeIn( 200::samp, 1.0, output );
            200::samp => now;

            // work through mainDuration
            mainDuration => now;

            // fade out
            fader.fadeOut( 200::samp, output );
            200::samp => now;
        }
    }

    fun dur getNextDur() {
        Time.bpmIntervalsShort.size() - 1 => int size;

        chooser.getInt(0, size) => int choice;

        Time.bpmIntervalsShort[choice] => float interval;

        if ( interval::second == delay.delay() ) {
            return getNextDur();
        }
        else {
            return interval::second;
        }
    }
}
