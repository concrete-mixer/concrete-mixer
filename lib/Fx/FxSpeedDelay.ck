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

public class FxSpeedDelay extends Fx {
    int delayBeat;

    Gain feedback;
    SpeedDelay delay;

    if ( ! Config.rpi ) {
        Chooser c;
        ( 60.0 / Config.bpm * Config.srate ) $ int => delayBeat;
        c.getInt(2, 4) * delayBeat => delay.delay;

        input => delay => output;
        c.getInt(0,1) => int doFeedback;

        if ( doFeedback ) {
            c.getFloat(0.25, 0.75) => feedback.gain;
        }
        else {
            0 => feedback.gain;
        }

        delay => feedback => input;
        60.0 / Config.bpm * 1000.0 => float beatInterval; // BI = beat interval in ms;
    }
    else {
        // do nothing
        input => output;
    }

    fun string idString() {
        return "FxSpeedDelay";
    }

    fun void initialise() {
        spork ~ activity();
    }

    fun void activity() {
        while ( active ) {
            1::second => now;
        }

        if ( ! Config.rpi ) {
            input =< delay =< output;
            delay =< feedback =< input;
        }
        else {
            input =< delay;
        }
    }
}
