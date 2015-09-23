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
        501::ms => delay.max;

        spork ~ activity();
    }

    fun void activity() {
        while ( active ) {
            chooser.getDur( 0.05, 0.50 ) => dur duration;
            duration => delay.delay;
            duration - 400::samp => duration;
            fader.fadeIn( 200::samp, 1.0, output );
            200::samp => now;
            duration => now;
            fader.fadeOut( 200::samp, output );
            200::samp => now;
        }
    }
}
