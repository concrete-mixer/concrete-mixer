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

Chooser chooser;
Panner panner;
Fader fader;


Gain inputGain;
Pan2 outputPan;
0 => outputPan.gain;

// spork ~ panner.initialise(outputPan);
Fx @ fxChain[];

UGen outLeft, outRight;

outLeft => Control.leftOut;
outRight => Control.rightOut;
Control.fxIn => inputGain;

// Fx chain is mono, let's make a little cheap stereo
Delay delay;
chooser.getDur( 0.001, 0.005 ) => delay.delay;

// should left side be delayed or right?
if ( chooser.getInt( 0, 1 ) ) {
    outputPan.left => outLeft;
    outputPan.right => delay => outRight;
}
else {
    outputPan.left => delay => outLeft;
    outputPan.right => outRight;
}

fxChainBuild();

// determine how long the chain will play for
[ 16, 20, 24, 28, 32 ] @=> int bars[];

bars[ chooser.getInt( 0, bars.cap() - 1 ) ] => int choice;

Control.barDur * choice => dur fxTime;
2 * Control.barDur => dur fadeTime;
fader.fadeIn( fadeTime, 0.7, outputPan );
fxTime - fadeTime => now;

fader.fadeOutBlocking( fadeTime, outputPan );
tearDown();

fun void fxChainBuild() {
    // Concrete.pm has a master array of choices, randomly sorted
    // so we can iterate through a full suite of fxChains without
    // repeating (at least until we've run out of choices)
    // Concrete.pm has the total count of fx and rpi-only fx hard-coded
    Std.atoi( me.arg(0) ) => int choice;

    // Define the fx chains. Originally we defined them randomly
    // but this meant much of the time the resulting chains were
    // suboptimal, if not nonsensical, so here we (lengthily) define
    // some reasonable sounding chains
    if ( choice == 1 ) {
        [
            new FxFilter,
            new FxDelay
        ] @=> fxChain;
    }

    if ( choice == 2 ) {
        [
            new FxDelayVariable,
            new FxDelay
        ] @=> fxChain;
    }

    if ( choice == 3 ) {
        [
            new FxDelay,
            new FxHarmonicDelay
        ] @=> fxChain;
    }

    if ( choice == 4 ) {
        [
            new FxHarmonicDelay,
            new FxDelay
        ] @=> fxChain;
    }

    if ( choice == 5 ) {
        [
            new FxFlanger,
            new FxDelay
        ] @=> fxChain;
    }

    if ( choice == 6 ) {
        [
            new FxFlanger,
            new FxDelayVariable
        ] @=> fxChain;
    }

    if ( choice == 7 ) {
        [
            new FxFilter,
            new FxDelayVariable
        ] @=> fxChain;
    }

    if ( choice == 8 ) {
        [
            new FxGate,
            new FxDelayVariable
        ] @=> fxChain;
    }

    if ( choice == 9 ) {
        [
            new FxDelay,
            new FxReverb,
            new FxChorus
        ] @=> fxChain;
    }

    if ( choice == 10 ) {
        [
            new FxDelay,
            new FxFilter,
            new FxReverb
        ] @=> fxChain;
    }

    if ( choice == 11 ) {
        [
            new FxDelay,
            new FxFlanger,
            new FxReverb
        ] @=> fxChain;
    }

    if ( choice == 12 ) {
        [
            new FxDelayVariable,
            new FxDelay
        ] @=> fxChain;
    }

    if ( choice == 13 ) {
        [
            new FxFilter,
            new FxGate,
            new FxDelay
        ] @=> fxChain;
    }

    if ( choice == 14 ) {
        [
            new FxRingMod,
            new FxFlanger,
            new FxDelay
        ] @=> fxChain;
    }

    if ( choice == 15 ) {
        [
            new FxRingMod,
            new FxFilter,
            new FxDelayVariable
        ] @=> fxChain;
    }

    if ( choice == 16 ) {
        [
            new FxRingMod,
            new FxHarmonicDelay,
            new FxDelay
        ] @=> fxChain;
    }

    // Beyond here all choices are for Control.rpi == 0 only
    // because they feature Chugens
    if ( choice == 17 ) {
        [
            new FxDelay,
            new FxDownSampler
        ] @=> fxChain;
    }

    if ( choice == 18 ) {
        [
            new FxDownSampler,
            new FxDelayVariable
        ] @=> fxChain;
    }

    if ( choice == 19 ) {
        [
            new FxDownSampler,
            new FxDelay,
            new FxFlanger
        ] @=> fxChain;
    }

    if ( choice == 20 ) {
        [
            new FxGate,
            new FxReverseDelay
        ] @=> fxChain;
    }

    if ( choice == 21 ) {
        [
            new FxFlanger,
            new FxReverseDelay
        ] @=> fxChain;
    }

    if ( choice == 22 ) {
        [
            new FxDelayVariable,
            new FxReverseDelay
        ] @=> fxChain;
    }

    if ( choice == 23 ) {
        [
            new FxFilter,
            new FxGate,
            new FxDelayVariable,
            new FxReverseDelay
        ] @=> fxChain;
    }

    if ( choice == 24 ) {
        [
            new FxFilter,
            new FxReverseDelay
        ] @=> fxChain;
    }

    if ( choice == 25 ) {
        [
            new FxGate,
            new FxReverseDelay
        ] @=> fxChain;
    }

    <<< "FX CHAIN: ", choice >>>;
    fxChainFx();
}

fun void fxChainFx() {
    for ( 0 => int i; i < fxChain.cap(); i++ ) {
        fxChain[ i ] @=> Fx fx;
        <<< i, fx.idString() >>>;
        fx.initialise();

        if ( i == 0 ) {
            inputGain => fx.input;
        }
        else {
            fxChain[ i - 1 ] @=> Fx upstreamFx;
            upstreamFx.output => fx.input;
        }

        if ( i == fxChain.cap() - 1 ) {
            fx.output => outputPan;
        }
    }

    <<< "END OF FXCHAIN DEBUG" >>>;
}

fun void tearDown() {
    for ( 0 => int i; i < fxChain.cap(); i++ ) {
        fxChain[ i ].tearDown();
    }

    // need to give time for teardown to process
    2::second => now;

    // now we go through and clean up
    for ( 0 => int i; i < fxChain.cap(); i++ ) {
        fxChain[ i ] @=> Fx fx;

        if ( i == 0 ) {
            inputGain =< fx.input;
        }
        else {
            fxChain[ i - 1 ] @=> Fx upstreamFx;
            upstreamFx.output =< fx.input;
        }

        if ( i == fxChain.cap() - 1 ) {
            fx.output =< outputPan;
        }
    }

    outputPan.left =< outLeft;
    outputPan.right =< outRight;

    outLeft =< Control.leftOut;
    outRight =< Control.rightOut;
    2::second => now;
    Control.oscSend.startMsg("playFxChain", "i");
    1 => Control.oscSend.addInt;
}
