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

me.arg(0) => string filepath;
me.arg(1) => string stream;

Std.atoi(me.arg(2)) => int playId;

chout <= "Playing stream" <= stream <= "filepath" <= filepath <= "playId" <= playId <= IO.nl();

// set up buf
SndBuf buf;
Config.sndBufChunks => int chunks;
chunks => buf.chunks;
filepath => buf.read;

// set up buf2 (may not be used if file is not two channel)
SndBuf buf2;

0 => buf.gain => buf2.gain;

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
    chunks => buf2.chunks;
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


fadeTime => now;

1 => buf.pos;

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

Mixer.oscOut.start("/playsound").add(stream).add(playId).send();

// End of execution

fun void playbackSingleChannel() {
    f.fadeInBlocking( fadeTime, 1.0, buf );
    activity();
    f.fadeOutBlocking( fadeTime, buf );
}

fun void playbackDoubleChannel() {
    1 => buf2.pos;
    0 => buf2.gain;
    f.fadeIn( fadeTime, 1.0, buf );
    f.fadeIn( fadeTime, 1.0, buf2 );
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
