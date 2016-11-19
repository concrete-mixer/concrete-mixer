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
    SndBuf buf;
    string filepath;
    dur duration;

    Chooser c;
    Panner p;
    LFO lfo;
    Fader f;

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
        if ( choice == 1 ) {
            reverse();
        }

        if ( choice == 2 ) {
            reepeat();
        }

        if ( choice == 3 ) {
            makeSlide();
        }

        if ( choice == 4 ) {
            xeno();
        }

        if ( choice == 5 ) {
            panBuf();
        }

        if ( choice == 6 ) {
            pitchOsc();
        }

        // all other choices involve applying Fx modules
        if ( choice > 6 ) {
            effecto(choice);
        }
    }

    // Generate choice integer for action
    // Only chugen now in operation here is reverseDelay
    fun int getChoice(dur duration) {
        // size of choices limited by config rpi setting
        15 => int endInt;
        1 => int startInt;

        // first option is reverse playback for duration
        // however if duration is longer than what's
        // already been played, this choice shouldn't
        // be an option
        if ( buf.pos()::samp - duration > 0::second ) {
            2 => startInt;
        }

        if ( Config.rpi ) {
            14 => endInt;
        }

        c.getInt( startInt, endInt ) => int choice;

        return choice;
    }

    fun void logSignalChange(string effect) {
        <<< effect, filepath, duration, "samples" >>>;
    }

    // apply Concrete Mixer Fx effects to signal
    fun void effecto( int choice ) {
        Fx effect;

        if ( choice == 6 ) {
            new FxReverb @=> effect;
        }

        if ( choice == 7 ) {
            new FxFlanger @=> effect;
        }

        if ( choice == 8 ) {
            new FxDelayVariable @=> effect;
        }

        if ( choice == 9 ) {
            new FxDelay @=> effect;
        }

        if ( choice == 10 ) {
            new FxDownSampler @=> effect;
        }

        if ( choice == 11 ) {
            new FxRingMod @=> effect;
        }

        if ( choice == 12 ) {
            new FxFeedback @=> effect;
        }

        // the following not invoked if Config.rpi
        if ( choice == 13 ) {
            new FxReverseDelay @=> effect;
        }

        <<< "EFFECTING", filepath, effect.idString() >>>;

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
        <<< "UNEFFECTING", filepath, effect.idString() >>>;
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
            // <<< oldPan, newPan, panAmountIncrement, currPan >>>;
            panTimeIncrement => now;
            panTimeIncrement -=> panTime;
        }

        <<< "oldPan", oldPan, "newPan", newPan, "panAmountIncrement", panAmountIncrement, "actual pan", p.pan.pan() >>>;

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
        <<< "Repeating", division, divisionLength, buf.gain() >>>;
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

    fun void pitchOsc() {
        1 / ( Time.bpmInterval * 16 ) => float lfoFreq;
        0.75 => float lfoAmount;

        // there's only one effect for stereo signals
        while ( duration > 0::second ) {
            lfo.osc( lfoFreq, lfoAmount, "sine" ) => float freqDelta;
            1 + freqDelta => buf.rate;

            Time.beatDur / 4 => dur targetDuration;

            targetDuration -=> duration;
            targetDuration => now;
        }

        // tidy things up
        1 => buf.rate;
    }
}
