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

me.dir() + "lib/" => string lib_path;

// Infrastructure modules:
Machine.add(lib_path + "Config.ck");
Machine.add(lib_path + "Time.ck");
Machine.add(lib_path + "Mixer.ck");
// (Dispatch.ck also infrastructural; added last)

// Utility classes
Machine.add(lib_path + "Utilities/Chooser.ck");
Machine.add(lib_path + "Utilities/LFO.ck");
Machine.add(lib_path + "Utilities/Fader.ck");
Machine.add(lib_path + "Utilities/Panner.ck");

// Fx classes
// Used by playFx and playSound (via AlterSignal)
Machine.add(lib_path + "Fx.ck");
Machine.add(lib_path + "Fx/FxDelay.ck");
Machine.add(lib_path + "Fx/FxDelayVariable.ck");
Machine.add(lib_path + "Fx/FxChorus.ck");
Machine.add(lib_path + "Fx/FxReverb.ck");
Machine.add(lib_path + "Fx/FxFilter.ck");
Machine.add(lib_path + "Fx/FxFlanger.ck");
Machine.add(lib_path + "Fx/FxGate.ck");
Machine.add(lib_path + "Fx/FxHarmonicDelay.ck");
Machine.add(lib_path + "Fx/FxRingMod.ck");
Machine.add(lib_path + "Fx/FxDownSampler.ck");
Machine.add(lib_path + "Fx/ReverseDelay.ck");
Machine.add(lib_path + "Fx/FxReverseDelay.ck");
Machine.add(lib_path + "Fx/SpeedDelay.ck");
Machine.add(lib_path + "Fx/FxSpeedDelay.ck");
Machine.add(lib_path + "Fx/FxFeedback.ck");
Machine.add(lib_path + "Fx/FxPassthrough.ck");

// Used by playSound to alter signal
// requires some fx libs, so added here
Machine.add(lib_path + "Utilities/AlterSignal.ck");
Machine.add(lib_path + "FxChain.ck");

// Finally Dispatch.ck manages execution of the app
Machine.add(lib_path + "Dispatch.ck");
