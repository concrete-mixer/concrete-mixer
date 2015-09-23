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


Fader f;

// set up UGens;
SndBuf buf;

Panner p;

Chooser c;
me.arg(0) => string filepath;
me.arg(1) => string type;

// set up buf
512 => buf.chunks;
filepath => buf.read;

// set up buf2 (may not be used if file is not stereo)
SndBuf buf2;

if ( buf.channels() == 1 ) {
    buf => p.pan;

    p.pan.left => Control.leftOut;
    p.pan.right => Control.rightOut;

    // send buf to fx
    // could make this conditional
    buf => Control.fxIn;
    c.getFloat( -1.0, 1.0 ) => p.pan.pan;
}
else {
    512 => buf2.chunks;
    filepath => buf2.read;
    1 => buf2.channel;

    // swap channels half the time
    if ( c.getInt( 0, 1 ) ) {
        buf => Control.leftOut;
        buf2 => Control.rightOut;
    }
    else {
        buf2 => Control.leftOut;
        buf => Control.rightOut;
    }

    buf => Control.fxIn;
    buf2 => Control.fxIn;
}

2 * Control.barDur => dur fadeTime;

0 => buf.gain;

<<< "Playing", filepath >>>;


if ( buf.channels() == 1 ) {
    f.fadeInBlocking( fadeTime, 0.8, buf );
    activity();
    f.fadeOutBlocking( fadeTime, buf );
}
else {
    0 => buf2.gain;
    f.fadeIn( fadeTime, 0.8, buf );
    f.fadeIn( fadeTime, 0.8, buf2 );
    buf.length() - fadeTime => now;
    f.fadeOut( fadeTime, buf );
    f.fadeOut( fadeTime, buf2 );
    fadeTime => now;
}


// disconnect
if ( buf.channels() == 1 ) {
    buf =< p.pan;
}
else {
    buf =< Control.leftOut;
    buf2 =< Control.rightOut;
}

p.pan.left =< Control.leftOut;
p.pan.right =< Control.rightOut;
Control.barLength::samp * 2 => now;

Control.oscSend.startMsg("playSound", "s");

type => Control.oscSend.addString;

fun void activity() {
    // define convenient threshold for checking if we should bail
    // for fadeout
    buf.length() - fadeTime => dur activityEnd;

    while ( buf.pos()::samp < activityEnd ) {
        // divvy up time in chunks relative to Control.bpm
        // and determine if we want to do something with them
        // Vary length between 3 and 6 bars
        Control.beatDur * 4 * c.getInt(3, 6) => dur duration;

        // if duration takes us beyond length of buf
        // play whatever we can and then return so
        // we can fade out
        if (
            buf.pos()::samp + duration > buf.length() ||
            buf.pos()::samp + duration > activityEnd
        ) {
            activityEnd - buf.pos()::samp => now;
            <<< "ACTIVITY ENDING" >>>;
            return;
        }

        // still here?
        // shall we do randomly do anything to the signal?
        if ( c.takeAction( 8 ) ) {
            alterSignal( duration );
        }
        else {
            duration => now;
        }
    }
}

// We've decided to do something random to the signal
// This function determines what that is
fun void alterSignal( dur duration ) {
    getAction( 1 ) => int choice;

    // first choices involve manipulating SndBuf playback
    if ( choice == 1 ) {
       if ( buf.pos()::samp - duration > 0::second ) {
            reverse( duration );
        }
        else {
            // pick something else then
            getAction( 2 ) => int choice;
        }
    }

    if ( choice == 2 ) {
        reepeat();
    }

    if ( choice == 3 ) {
        makeSlide( duration );
    }

    if ( choice == 4 ) {
       xeno( duration );
    }

    if ( choice == 5 ) {
        dawdle( duration );
    }

    if ( choice == 6 ) {
        panBuf( duration );
    }

    // all other choices involve applying Fx modules
    if ( choice > 6 ) {
        effecto(duration, choice);
    }
}

// Generate choice integer for action
// Only chugen now in operation here is reverseDelay
fun int getAction( int startInt ) {
    // size of choices limited by config rpi setting
    13 => int endInt;

    if ( Control.rpi ) {
        12 => endInt;
    }

    c.getInt( startInt, endInt ) => int choice;

    return choice;
}

fun void effecto( dur duration, int choice ) {
    Fx effect;

    if ( choice == 7 ) {
        new FxReverb @=> effect;
    }

    if ( choice == 8 ) {
        new FxFlanger @=> effect;
    }

    if ( choice == 9 ) {
        new FxDelayVariable @=> effect;
    }

    if ( choice == 10 ) {
        new FxDelay @=> effect;
    }

    if ( choice == 11 ) {
        new FxDownSampler @=> effect;
    }

    if ( choice == 12 ) {
        new FxRingMod @=> effect;
    }

    // the following not invoked if Control.rpi
    if ( choice == 13 ) {
        new FxReverseDelay @=> effect;
    }

    <<< "EFFECTING", filepath, effect.idString() >>>;
    buf => effect.input;
    effect.output => Pan2 fpan;
    p.pan.pan() => fpan.pan;
    fpan.left => Control.leftOut;
    fpan.right => Control.rightOut;
    0 => fpan.gain;

    effect.initialise();

    f.fadeOut( duration / 2, p.pan );
    f.fadeIn( duration / 2, 0.8, fpan );

    duration / 2  => now;

    f.fadeIn( duration / 2, 0.8, p.pan );
    f.fadeOut( duration / 2, effect.output );
    duration / 2  => now;
    0 => effect.active;

    fpan =< Control.leftOut;
    fpan =< Control.rightOut;
    <<< "UNEFFECTING", filepath, effect.idString() >>>;
}

fun void panBuf ( dur duration ) {
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

fun void reverse( dur duration) {
    reverseMessage( "REVERSING", duration );
    setRate( -1.0 );
    duration => now;
    reverseMessage( "UNREVERSING", duration );
    setRate( 1.0 );
}

fun void reepeat() {
    [ 3, 4, 5, 6, 8 ] @=> int divisions[];
    c.getInt(0, divisions.cap() - 1 ) => int choice;
    divisions[ choice ] => int division;

    ( Control.barLength / division ) $ int => int divisionLength;
    buf.pos() => int repeatoPos;
    5::ms => dur miniFadeTime;

    c.getInt( 1, 8 ) => int repeato;

    <<< "Reepeating", division, divisionLength, buf.gain() >>>;
    0 => buf.gain;

    for ( 0 => int i; i < repeato; i++ ) {
        f.fadeInBlocking( miniFadeTime, 0.8, buf );
        divisionLength::samp - ( 2 * miniFadeTime ) => now;
        f.fadeOutBlocking( miniFadeTime, buf );
        repeatoPos => buf.pos;

        if ( ! c.getInt( 0, 3 ) ) {
            setRate( -1 );
        }
        else {
            setRate( 1 );
        }
    }

    setRate( 1 );

    f.fadeInBlocking( miniFadeTime, 0.8, buf );
}

fun void makeSlide( dur duration ) {
    dur leftoverdur;
    int denominator;

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
            setRate( currRate + rateIncrement );
        }
        else {
            setRate( currRate - rateIncrement );
        }

        timeIncrement => now;
        timeIncrement -=> slideTime;
    }
}

fun void xeno( dur durdur ) {
    durdur / 12 => durdur;

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

// Make playback run slower by oscillating back and forth
// This didn't sound as interesting as you'd think, esp
// with environmental sounds where the action is often spaced out
// so I've made it a bit more interesting by randomly changing the
// pitch. As you do.
fun void dawdle( dur duration ) {
    [ 2, 3, 4, 5, 5, 7, 9, 10 ] @=> int forwardRatios[];
    [ 1, 1, 1, 1, 2, 2, 2, 3  ] @=> int backwardRatios[];

    100::samp => dur fadeDur;
    buf.gain() => float origGain;
    dur stepDur;

    while ( duration > stepDur ) {
        c.getInt( 0, forwardRatios.cap() - 1 ) => int choice;
        forwardRatios[ choice ] => int forwardRatio;
        backwardRatios[ choice ] => int backwardRatio;

        Control.beatDur / 16 => dur dur64;
        dur64 * forwardRatio => dur forwardDur;

        dur64 / samp => float dur64samples;
        dur64samples $int * backwardRatio $ int => int backwardSamples;

        f.fadeOutBlocking( fadeDur, buf );

        f.fadeIn( fadeDur, origGain, buf );

        if ( c.getInt( 0, 1 ) ) {
            [ 0.8, 1.2, 1.5 ] @=> float pitches[];

            pitches[ c.getInt(0, pitches.cap() -1 ) ] => buf.rate;
        }

        forwardDur - fadeDur => now;
        f.fadeOutBlocking( fadeDur, buf );
        buf.pos() - backwardSamples => buf.pos;
        forwardDur -=> duration;
        1.0 => buf.rate;
    }

    f.fadeInBlocking( fadeDur, origGain, buf );
}

// While developing this I want to tune the amount of reversing that
// that goes on across a stanza. This function logs what's going on
fun void reverseMessage( string type, dur duration ) {
    <<< "playSound:", type, filepath, duration / Control.srate >>>;
}

fun void setRate( float rate ) {
    buf.rate( rate );
}
