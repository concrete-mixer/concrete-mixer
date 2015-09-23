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
Std.atof( me.arg(0) ) => float bpm;
Std.atoi( me.arg(1) ) => int srate;
Std.atoi( me.arg(2) ) => int record;
Std.atoi( me.arg(3) ) => int rpi;
me.dir() + "/../.." => string lib_path;

Machine.add(lib_path + "/Control.ck:" + bpm + ":" + srate + ":" + record + ":" + rpi);
Machine.add(lib_path + "/Chooser.ck");
Machine.add(lib_path + "/LFO.ck");
Machine.add(lib_path + "/Fader.ck");
Machine.add(lib_path + "/Panner.ck");
Machine.add(lib_path + "/Fx.ck");
Machine.add(lib_path + "/Fx/FxDelay.ck");
Machine.add(lib_path + "/Fx/FxDelayVariable.ck");
Machine.add(lib_path + "/Fx/FxChorus.ck");
Machine.add(lib_path + "/Fx/FxReverb.ck");
Machine.add(lib_path + "/Fx/FxFilter.ck");
Machine.add(lib_path + "/Fx/FxFlanger.ck");
Machine.add(lib_path + "/Fx/FxGate.ck");
Machine.add(lib_path + "/Fx/FxHarmonicDelay.ck");
Machine.add(lib_path + "/Fx/FxRingMod.ck");
Machine.add(lib_path + "/Fx/FxDownSampler.ck");
Machine.add(lib_path + "/Fx/ReverseDelay.ck");
Machine.add(lib_path + "/Fx/FxReverseDelay.ck");
