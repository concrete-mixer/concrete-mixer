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

/*
    Parent class for all Fx* modules
*/
public class Fx {
    Chooser chooser;
    1 => int active;

    Gain input, output;

    fun string idString() { return "Fx"; }

    fun void initialise() {}

    fun void connectToFxChain( Gain targetGain ) {}

    // sets active to false, so when fx.execute while block
    // next loops, it will shut down
    fun void tearDown() {
        <<< "calling Fx.tearDown()" >>>;
        0 => active;
    }
}
