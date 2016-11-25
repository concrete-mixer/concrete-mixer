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


Fader f;
Panner p;

// set up UGens;
SndBuf buf;

Chooser c;
AlterSignal as;

me.arg(0) => string filepath;
me.arg(1) => string stream;

chout <= "Playing stream" <= stream <= filepath <= IO.nl();

// set up buf
512 => buf.chunks;
filepath => buf.read;


// set up buf2 (may not be used if file is not stereo)
SndBuf buf2;

if ( buf.channels() == 1 ) {
    buf => p.pan;

    p.pan.left => Mixer.leftOut;
    p.pan.right => Mixer.rightOut;

    // send buf to fx
    // could make this conditional
    buf => Mixer.fxIn;
    c.getFloat( -1.0, 1.0 ) => p.pan.pan;

    as.initialise( filepath, p, f, buf );
}
else {
    512 => buf2.chunks;
    filepath => buf2.read;
    1 => buf2.channel;

    // swap channels half the time
    if ( c.getInt( 0, 1 ) ) {
        buf => Mixer.leftOut;
        buf2 => Mixer.rightOut;
    }
    else {
        buf2 => Mixer.leftOut;
        buf => Mixer.rightOut;
    }

    buf => Mixer.fxIn;
    buf2 => Mixer.fxIn;
}

2 * Time.barDur => dur fadeTime;

0 => buf.gain;

if ( buf.channels() == 1 ) {
    playbackSingleChannel();
}
else {
    playbackDoubleChannel();
}


// disconnect
if ( buf.channels() == 1 ) {
    buf =< p.pan;
}
else {
    buf =< Mixer.leftOut;
}

p.pan.left =< Mixer.leftOut;
p.pan.right =< Mixer.rightOut;

Time.barDur * 2 => now;
Mixer.oscOut.start("/playsound").add(stream).send();

// End of execution

fun void playbackSingleChannel() {
    f.fadeInBlocking( fadeTime, 0.8, buf );
    activity();
    f.fadeOutBlocking( fadeTime, buf );
}

fun void playbackDoubleChannel() {
    0 => buf2.gain;
    f.fadeIn( fadeTime, 0.8, buf );
    f.fadeIn( fadeTime, 0.8, buf2 );
    buf.length() - fadeTime => now;
    f.fadeOut( fadeTime, buf );
    f.fadeOut( fadeTime, buf2 );
    fadeTime => now;
}

fun void activity() {
    // define threshold for checking if we should bail
    // for fadeout
    buf.length() - fadeTime => dur activityEndPoint;

    while ( buf.pos()::samp < activityEndPoint ) {
        // divvy up time in chunks relative to Config.bpm
        // and determine if we want to do something with them
        // Vary length between 3 and 6 bars
        Time.beatDur * 4 * c.getInt(3, 6) => dur duration;

        // if duration takes us beyond length of buf
        // play whatever we can and then return so
        // we can fade out
        if (
            buf.pos()::samp + duration > buf.length() ||
            buf.pos()::samp + duration > activityEndPoint
        ) {
            activityEndPoint - buf.pos()::samp => now;
            <<< "ACTIVITY ENDING" >>>;
            return;
        }

        // still here?
        // shall we do anything to the signal?
        if ( c.takeAction( 8 ) ) {
            // delegate duration to AlterSignal
            <<< "ALTERING SIGNAL ON", filepath >>>;
            as.alterSignal( duration );
        }
        else {
            // let playback happen normally
            duration => now;
        }
    }
}
