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

public class ReverseDelay extends Chugen {
    float readArray[0];
    float writeArray[0];
    int readCount;
    int writeCount;
    float sample;

    fun void delay( int size ) {
        readArray.size( size );
        writeArray.size( size );
        size - 1 => readCount;
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
        readCount--;

        if ( writeCount == writeArray.cap() ) {
            switchArrays();
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
        readArray.cap() - 1 => readCount;
    }
}
