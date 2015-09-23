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

public class Panner extends LFO {
    10 => int actionDenominator;
    5.0 => float waitMin;
    15 => float waitMax;
    [ "fixed point", "LFO" ] @=> string panTypes[];
    1 => int active;

    Pan2 pan;

    fun void initialise( Pan2 inputPan ) {
        inputPan @=> pan;
        setType();
    }

    fun void setType() {
        chooser.getInt( 0, panTypes.cap() - 1 ) => int i;
        panTypes[ i ] => string panType;

        // this sets the pan to an arbitary position between left and right
        if ( panType == "fixed point" ) {
            chooser.getFloat( -1.0, 1.0 ) => float position;
            setPan( pan, position );
        }

        // finally, apply dynamic pan based on LFO
        if ( panType == "LFO" ) {
            makeLFOPan();
        }
    }

    fun string getOscType() {
        [ "sine", "square" ] @=> string oscTypes[];

        return oscTypes[ chooser.getInt( 0, oscTypes.cap() - 1 ) ];
    }

    fun void setPan( Pan2 pan, float position ) {
        position => pan.pan;
    }

    fun void changePan( float freq, float amount, string oscType ) {
        while ( active ) {
            osc( freq, amount, oscType ) => float position;
            setPan( pan, position );
            100 :: ms => now;
        }
    }

    // set LFO type and generate LFO frequencies and amounts for panning
    fun void makeLFOPan() {
        getOscType() => string oscType;
        float freq;
        float amount;

        // sine pans work better slower, while square wave pans work
        // better faster but shallower, so we need to tweak a bit
        if ( oscType == "sine" ) {
            chooser.getFloat( 0.05, 0.25 ) => freq;
            chooser.getFloat( 0.5, 1.0 ) => amount;
        }

        if ( oscType == "square" ) {
            chooser.getFloat( 0.5, 5 ) => freq;
            chooser.getFloat( 0.2, 0.5 ) => amount;
        }
        <<< "PanGain running changePan(): freq", freq, "amount", amount, "duration", "oscillator type", oscType >>>;
        spork ~ changePan( freq, amount, oscType );
    }

    fun void panFromFixed( float freq, float amount, string type, dur duration ) {
        0::second => dur epoch;

        while ( duration > 0::second ) {
            Math.cos( epoch / second * Math.PI * 2 ) * amount => float val;
            val => pan.pan;
            50::ms -=> duration;
            50::ms +=> epoch;
            50::ms => now;
        }
    }

    fun void tearDown() {
        0 => active;
    }
}

