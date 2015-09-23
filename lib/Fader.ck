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

public class Fader {
    // this is the number of steps through which the fade will iterate
    // 100 seems reasonable
    100 => static int steps;

    fun static dur getTimeIncrement( dur fadeTime ) {
        return fadeTime / steps;
    }

    fun static float getGainIncrement( float finalGain ) {
        return finalGain / steps;
    }

    fun static void fadeIn( dur fadeTime, float finalGain, UGen gen ) {
        getTimeIncrement( fadeTime )  => dur timeIncrement;
        getGainIncrement( finalGain ) => float gainIncrement;

        spork ~ fade( fadeTime, timeIncrement, gainIncrement, gen );
    }

    fun static void fadeOut( dur fadeTime, UGen gen ) {
        getTimeIncrement( fadeTime ) => dur timeIncrement;
        getGainIncrement( gen.gain() ) => float gainIncrement;
        -gainIncrement => gainIncrement;

        spork ~ fade( fadeTime, timeIncrement, gainIncrement, gen );
    }

    fun static void fadeInBlocking( dur fadeTime, float finalGain, UGen gen ) {
        getTimeIncrement( fadeTime )  => dur timeIncrement;
        getGainIncrement( finalGain ) => float gainIncrement;

        fade( fadeTime, timeIncrement, gainIncrement, gen );
    }

    fun static void fadeOutBlocking( dur fadeTime, UGen gen ) {
        getTimeIncrement( fadeTime ) => dur timeIncrement;
        getGainIncrement( gen.gain() ) => float gainIncrement;
        -gainIncrement => gainIncrement;

        fade( fadeTime, timeIncrement, gainIncrement, gen );
    }

    fun static void fade( dur fadeTime, dur timeIncrement, float gainIncrement, UGen gen ) {
        while( fadeTime > 0::second ) {
            gen.gain() => float currGain;
            currGain + gainIncrement => float newGain;
            newGain => gen.gain;
            timeIncrement -=> fadeTime;
            timeIncrement => now;
        }
    }
}
