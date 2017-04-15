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

Chooser c;
AlterSignal as;
Config.debug => int debug;

me.arg(0) => string filepath;
me.arg(1) => string stream;

Std.atoi(me.arg(2)) => int playId;

<<< "Playing stream", stream ,  "filepath" ,  filepath ,  "playId" ,  playId >>>;

Mixer.bufs[playId] @=> SndBuf2 buf;

// set up buf
Config.sndBufChunks => int chunks;

if ( buf.chunks() == Config.sndBufChunks ) {
    chunks => buf.chunks;
}

2 * Time.barDur => dur fadeTime;

0 => buf.gain;
filepath => buf.read;
fadeTime => now; // gives time to read in first part of file

// This is only relevant for Concrete Mixer Radio
if ( Config.oscWeb ) {
    // Tell the web server something's happening
    Mixer.oscWeb.start("/playsound").add(filepath).add(stream).send();
}

1 => buf.pos; // sets buf pos back to start

if ( buf.channels() == 1 ) {
    buf => p.pan;

    p.pan.left => Mixer.leftOut;
    p.pan.right => Mixer.rightOut;

    // send buf to fx
    // could make this conditional
    c.getFloat( -1.0, 1.0 ) => p.pan.pan;

    as.initialise( filepath, p, f, buf );
}
else {
    // swap channels half the time
    if ( c.getInt( 0, 1 ) ) {
        buf.chan(0) => Mixer.leftOut;
        buf.chan(1) => Mixer.rightOut;
    }
    else {
        buf.chan(1) => Mixer.leftOut;
        buf.chan(0) => Mixer.rightOut;
    }
}


1 => buf.pos;

if ( buf.channels() == 1 ) {
    playbackSingleChannel();
}
else {
    playbackDoubleChannel();
}

if ( buf.channels() == 1 ) {
    buf =< p.pan;
    p.pan.left =< Mixer.leftOut;
    p.pan.right =< Mixer.rightOut;
}
else {
    // need to cover all permutations as we mix it up a bit
    buf.chan(0) =< Mixer.leftOut;
    buf.chan(0) =< Mixer.rightOut;
    buf.chan(1) =< Mixer.leftOut;
    buf.chan(1) =< Mixer.rightOut;
}

Mixer.oscOut.start("/playsound").add(stream).add(playId).send();

// End of execution

fun void playbackSingleChannel() {
    f.fadeInBlocking( fadeTime, 1.0, buf );
    activity();
    f.fadeOutBlocking( fadeTime, buf );
}

fun void playbackDoubleChannel() {
    f.fadeIn( fadeTime, 0.5, buf );
    buf.length() - fadeTime => now;
    f.fadeOut( fadeTime, buf );
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
            if ( debug ) { <<< "ACTIVITY ENDING" >>>; }
            return;
        }

        // still here?
        // shall we do anything to the signal?
        if ( c.takeAction( 8 ) ) {
            // delegate duration to AlterSignal
            if ( debug ) { <<< "ALTERING SIGNAL ON", filepath >>>; }
            as.alterSignal( duration );
        }
        else {
            // let playback happen normally
            duration => now;
        }
    }
}
