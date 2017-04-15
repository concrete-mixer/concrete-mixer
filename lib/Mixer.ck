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

/*
    Declare public class with static variables all libraries can access
    Due to Kassen, see http://wiki.cs.princeton.edu/index.php/buses
*/
public class Mixer {
    static Gain @ leftOut;
    static Gain @ rightOut;
    static Gain @ fxIn;
    static SndBuf2 @ bufs[];

    static OscOut @ oscOut;
    static OscOut @ oscWeb;
}

// populate vars
new Gain @=> Mixer.leftOut;
new Gain @=> Mixer.rightOut;
new Gain @=> Mixer.fxIn;

Dyno dynoL => dac.left;
Dyno dynoR => dac.right;

dynoL.limit();
dynoR.limit();

Mixer.leftOut => dynoL; // left 'dry' out
Mixer.rightOut => dynoR; // right 'dry' out

0.3 => Mixer.fxIn.gain;

Mixer.fxIn => Mixer.leftOut;
Mixer.fxIn => Mixer.rightOut;

// playSound and playFx use this OscOut to send requests back to the dispatch
// listener.
new OscOut @=> Mixer.oscOut;
("localhost", 2424) => Mixer.oscOut.dest;

if ( Config.oscWeb ) {
    new OscOut @=> Mixer.oscWeb;
    ("localhost", Config.oscWebPort) => Mixer.oscWeb.dest;
}

if ( Config.record ) {
    WvOut2 wv;
    "concrete-mixer-output" => wv.autoPrefix;

    // this is the output file name
    "special:auto" => wv.wavFilename;

    Mixer.fxIn => blackhole;
    dac => wv => blackhole;
    null @=> wv;
}

Config.streamData.getTotalConcurrentSounds() => int bufTot;

SndBuf2 bufs[bufTot];

bufs @=> Mixer.bufs;

for ( int i; i < bufs.size(); i++ ) {
    Mixer.bufs[i] @=> SndBuf2 buf;
    buf => Mixer.fxIn;
}

while ( ! Config.ended ){
    1::second => now;
}
