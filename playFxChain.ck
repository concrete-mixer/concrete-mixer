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
This file is now mighty short because all the fx chain functionality
has been moved to lib/FxChain.ck.

The separation of concerns is: FxChain takes care of the chain management,
while this file looks after the control of the chain (how long it will
execute, its shutdown, OSC calls).
*/

Chooser chooser;

FxChain chain;

chain.fxChainBuild();

// determine how long the chain will play for
[ 16, 20, 24, 28, 32 ] @=> int bars[];

bars[ chooser.getInt( 0, bars.cap() - 1 ) ] => int choice;

Time.barDur * choice => dur fxTime;
2 * Time.barDur => dur fadeTime;

chain.fadeIn( fadeTime );
fxTime - fadeTime => now;

chain.fadeOut( fadeTime );
chain.tearDown();

Mixer.oscOut.start("/playfxchain").add(1).send();
