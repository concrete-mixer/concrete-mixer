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

// This class used to use a chugen which copied bitcrusher
// After getting chugins to (finally) work, we now use actual bitcrusher
public class FxDownSampler extends Fx {
    Chooser c;
    Bitcrusher bc;
    int oldBittage;
    int oldDecimation;

    fun string idString() { return "FxDownSampler"; }

    fun void initialise() {
        input => bc => output;

        spork ~ activity();
    }


    fun void activity() {
        while ( active ) {
            getDecimation() => int decimation;
            decimation => bc.downsampleFactor;
            getBits() => int bits;
            bits => bc.bits;

            c.getInt(0, Control.bpmIntervalsShort.cap() - 1 ) => int intervalChoice;
            Control.bpmIntervalsShort[ intervalChoice ]::second => now;
        }

        input =< bc =< output;
    }

    fun int getDecimation() {
        [ 1, 2, 3, 4, 6, 8, 12, 16, 24 ] @=> int options[];

        options[ c.getInt( 0, options.cap() - 1 ) ] => int decimation;

        if ( decimation == oldDecimation ) {
            return getDecimation();
        }
        else {
            decimation => oldDecimation;
            return decimation;
        }
    }

    fun int getBits() {
        [ 7, 8, 9, 10, 11, 12 ] @=> int options[];

        options[ c.getInt( 0, options.cap() - 1 ) ] => int bittage;

        // ensure we always return something different from the old one
        if ( bittage == oldBittage ) {
            return getBits();
        }
        else {
            bittage => oldBittage;
            return bittage;
        }
    }
}
