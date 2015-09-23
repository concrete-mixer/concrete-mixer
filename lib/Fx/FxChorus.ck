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

public class FxChorus extends Fx {
    Chorus chorus;

    input => chorus => output;

    fun string idString() { return "FxChorus"; }

    fun void initialise() {
        1 => active;

        float freq, depth;
        Control.bpmIntervalsLong @=> float chorusFreqs[];

        1 / chorusFreqs[ chooser.getInt( 0, chorusFreqs.cap() - 1 ) ] => freq;
        chooser.getFloat( 0.1, 0.3 ) => depth;
        chooser.getFloat( 0.1, 0.6 ) => float mix;

        <<< "   FxChorus: freq", freq, "depth", depth, "mix", mix >>>;
        freq => chorus.modFreq;
        depth => chorus.modDepth;
        mix => chorus.mix;
    }
}
