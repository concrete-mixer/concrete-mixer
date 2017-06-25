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

public class AlterSignal {
    SndBuf @ buf;
    string filepath;
    dur duration;

    Chooser c;
    Panner p;
    LFO lfo;
    Fader f;
    Config.debug => int debug;

    fun void initialise( string filepathIn, Panner pIn, Fader fIn, SndBuf bufIn ) {
        bufIn @=> buf;
        filepathIn => filepath;
        pIn @=> p;
        fIn @=> f;
    }

    fun void alterSignal(dur durationIn) {
        durationIn => duration;

        getChoice(duration) => int choice;

        // first choices involve manipulating SndBuf playback
        // note there are some manipulations not used but could be reinstated:
        // octavate() and makeslide()
        if ( choice == 1 ) {
            reverse();
        }

        if ( choice == 2 ) {
            reepeat();
        }

        if ( choice == 3 ) {
            xeno();
        }

        if ( choice == 4 ) {
            panBuf();
        }

        // all other choices involve applying Fx modules
        if ( choice == 5 ) {
            effecto(choice);
        }
    }

    // Generate choice integer for action
    // Only chugen now in operation here is reverseDelay
    fun int getChoice(dur duration) {
        // size of choices limited by config rpi setting
        5 => int endInt;
        1 => int startInt;

        // first option is reverse playback for duration
        // however if duration is longer than what's
        // already been played, this choice shouldn't
        // be an option
        if ( buf.pos()::samp - duration > 0::second ) {
            2 => startInt;
        }

        if ( Config.rpi ) {
            5 => endInt;
        }

        c.getInt( startInt, endInt ) => int choice;

        return choice;
    }

    fun void logSignalChange(string effect) {
        if ( debug ) { <<< effect, filepath, duration, "samples" >>>; }
    }

    // Apply Concrete Mixer Fx effects to buf signal
    // we used to put more things on (flange, reverse delay, etc)
    // but for now there's just one in use
    fun void effecto( int choice ) {
        Fx effect;

        if ( choice == 5 ) {
            new FxFeedback @=> effect;
        }

        if ( debug ) { <<< "EFFECTING", filepath, effect.idString() >>>; }

        buf => effect.input;

        effect.output => Pan2 fpan;

        p.pan.pan() => fpan.pan;
        fpan.left => Mixer.leftOut;
        fpan.right => Mixer.rightOut;
        0 => fpan.gain;

        effect.initialise();

        f.fadeOut( duration / 2, p.pan );
        f.fadeIn( duration / 2, 0.8, fpan );

        duration / 2  => now;

        f.fadeIn( duration / 2, 0.8, p.pan );
        f.fadeOut( duration / 2, effect.output );
        duration / 2  => now;
        0 => effect.active;

        fpan =< Mixer.leftOut;
        fpan =< Mixer.rightOut;

        if ( debug ) { <<< "UNEFFECTING", filepath, effect.idString() >>>; }
    }

    fun void panBuf() {
        p.pan.pan() => float oldPan;

        // first, determine new pan position
        float newPan, panAmountIncrement, difference;
        dur panTimeIncrement;

        duration / 4 => dur panTime;
        panTime / 100 => panTimeIncrement;

        if ( oldPan < 0 ) {
            c.getFloat( 0, 1.0 ) => newPan;
            ( newPan - oldPan ) => difference;
        }
        else {
            c.getFloat( -1.0, 0 ) => newPan;
            - ( oldPan - newPan ) => difference;
        }

        if ( Math.fabs( difference ) < 0.5 ) {
            0.5 => difference;

            if ( difference < 0 ) {
                - difference => difference;
            }
        }

        difference / 100 => panAmountIncrement;

        while ( panTime > 0::second ) {
            p.pan.pan() => float currPan;
            currPan + panAmountIncrement => p.pan.pan;
            panTimeIncrement => now;
            panTimeIncrement -=> panTime;
        }

        if ( debug ) { <<< "oldPan", oldPan, "newPan", newPan, "panAmountIncrement", panAmountIncrement, "actual pan", p.pan.pan() >>>; }

        duration => now;
    }

    fun void reverse() {
        logSignalChange("Reversing");
        -1.0 => buf.rate;
        duration => now;
        logSignalChange("Unreversing");
        1.0 => buf.rate;
    }

    fun void reepeat() {
        [ 3, 4, 5, 6, 8 ] @=> int divisions[];
        c.getInt(0, divisions.cap() - 1 ) => int choice;
        divisions[ choice ] => int division;

        ( Time.barLength / division ) $ int => int divisionLength;
        buf.pos() => int repeatoPos;
        5::ms => dur miniFadeTime;

        c.getInt( 1, 8 ) => int repeato;

        logSignalChange("Reepeating");
        if ( debug ) { <<< "Repeating", division, divisionLength, buf.gain() >>>; }
        0 => buf.gain;

        for ( 0 => int i; i < repeato; i++ ) {
            f.fadeInBlocking( miniFadeTime, 0.8, buf );
            divisionLength::samp - ( 2 * miniFadeTime ) => now;
            f.fadeOutBlocking( miniFadeTime, buf );
            repeatoPos => buf.pos;

            if ( ! c.getInt( 0, 3 ) ) {
                -1 => buf.rate;
            }
            else {
                1 => buf.rate;
            }
        }

        1 => buf.rate;

        f.fadeInBlocking( miniFadeTime, 0.8, buf );
    }

    fun void makeSlide() {
        dur leftoverdur;
        int denominator;

        logSignalChange("MakeSlide");

        c.getInt( 4, 16 ) => denominator;
        slideRate( "down" , duration / denominator );
        duration - ( duration / denominator ) => leftoverdur;
        c.getInt( 4, 8 ) => denominator;
        duration / denominator => now;
        leftoverdur - ( duration / denominator ) => leftoverdur;

        c.getInt( 4, 16 ) => denominator;
        slideRate( "up" , duration / denominator );
        leftoverdur - ( duration / denominator ) => leftoverdur;

        leftoverdur => now; // should all add up to duration
    }

    fun void slideRate( string type, dur slideTime ) {
        logSignalChange("SlideRate");

        slideTime / 100 => dur timeIncrement;

        1 / 100.0 => float rateIncrement;

        1 => float endRate;

        if ( type == "down" ) {
            0 => endRate;
        }

        float currRate;

        while ( slideTime > 0::second ) {
            buf.rate() => currRate;

            if ( type == "up" ) {
                currRate + rateIncrement => buf.rate;
            }
            else {
                currRate - rateIncrement => buf.rate;
            }

            timeIncrement => now;
            timeIncrement -=> slideTime;
        }
    }

    fun void xeno() {
        // as in xeno's paradox, in that this sort of does an
        // audio equivalent ('cept not really)
        logSignalChange("Xeno");

        duration / 12 => dur durdur;

        while ( durdur > 1::samp ) {
            durdur => now;
            buf.rate( -1 );

            // the following values are arbitrary TODO: something more asymptotic
            durdur * ( 5.0 / 6.0 ) => dur newdur;
            newdur => now;
            newdur => durdur;
            buf.rate( 1 );
        }
    }

    fun void octavate() {
        duration / 4 => dur length;
        buf.pos() => int pos;
        1 => int octave;

        while ( octave < 8 ) {
            <<< octave, length, pos >>>;
            octave => buf.rate;
            length / 2 => length;
            length => now;
            octave++;
            pos => buf.pos;
        }

        1 => buf.rate;
        ( duration / 2 ) => now;
    }
}
