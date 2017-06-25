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

public class SpeedDelay extends Chugen {
    float readArray[0];
    float writeArray[0];
    int readCount;
    int writeCount;
    float sample;
    1 => float skip;
    int arrSize;
    Chooser c;
    [0.5, 1, 2, 3] @=> float ratios[];
    0 => int skipPos;
    int max;

    fun void delay( int size ) {
        readArray.size( size );
        writeArray.size( size );
        size => arrSize;
        0 => readCount;
    }

    fun float tick( float in ) {
        // if readArray.size(), delay() has not been called
        // do nothing
        if ( ! readArray.cap() ) {
            return in;
        }

        in => writeArray[ writeCount ];

        readArray[ readCount ] => sample;
        writeCount++;

        if ( skip < 1 ) {
            if (skipPos < max) {
                skipPos++;
            }
            else {
                readCount++;
                0 => skipPos;
            }
        }
        else {
            skip $ int +=> readCount;
        }

        if ( readCount >= arrSize ) {
            0 => readCount;
        }

        if ( writeCount == arrSize ) {
            switchArrays();
            resetSkip();
        }

        return sample;
    }

    fun void switchArrays() {
        float tempArray[];

        // switch arrays
        readArray @=> tempArray;
        writeArray @=> readArray;
        tempArray @=> writeArray;

        // reset counts
        0 => writeCount;
    }


    fun void resetSkip() {
        0 => readCount;

        getRatio() => skip;
    }

    fun float getRatio() {
        c.getInt(0, ratios.size() - 1) => int choice;

        ratios[choice] => float newSkip;

        if ( newSkip == skip ) {
            return getRatio();
        }

        if ( newSkip < 1 ) {
            ( 1.0 / skip ) $ int => max;
        }

        return newSkip;
    }
}
