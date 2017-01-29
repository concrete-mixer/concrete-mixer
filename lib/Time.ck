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

public class Time {
    static float bpmInterval;
    static float bpmIntervalsShort[];
    static float bpmIntervalsMedium[];
    static float bpmIntervalsLong[];

    static dur beatDur;
    static int beatLength;

    static dur barDur;
    static int barLength;
}

fun void setTimeData() {
    ( 60 / Config.bpm ) => float bpmInterval;
    bpmInterval => Time.bpmInterval;

    [
         bpmInterval / 8,
         bpmInterval / 6,
         bpmInterval / 5 * 2,
         bpmInterval / 4, // quaver
         bpmInterval / 3,
         bpmInterval / 2,
         bpmInterval / 3 * 2,
         bpmInterval / 4 * 3, // 3 quavers
         bpmInterval * ( 3.0 / 2.0 ),
         bpmInterval * 2,
         bpmInterval * ( 5.0 / 2.0 )
    ] @=> Time.bpmIntervalsShort;

    [
        bpmInterval / 4,
        bpmInterval / 3,
        bpmInterval / 2,
        bpmInterval / 4 * 3, // 3 quavers
        bpmInterval,
        bpmInterval * ( 4.0 / 3.0 ),
        bpmInterval * 1.5,
        bpmInterval * ( 5.0 / 3.0 ),
        bpmInterval * 2.0,
        bpmInterval * 2.5,
        bpmInterval * 3.0,
        bpmInterval * 4.0,
        bpmInterval * 5.0,
        bpmInterval * 5.0,
        bpmInterval * 8.0
    ] @=> Time.bpmIntervalsMedium;

    [
         bpmInterval * 4,     // 1 'bar'
         bpmInterval * 4 * 2, // 2 'bars'
         bpmInterval * 4 * 2.5, // 2 'bars'
         bpmInterval * 4 * 3, // 3 'bars'
         bpmInterval * 14,    // 3.5 'bars'
         bpmInterval * 4 * 4, // 4 'bars'
         bpmInterval * 3 * 6, // 4.5
         bpmInterval * 4 * 5, // 5
         bpmInterval * 4 * 6, // 6
         bpmInterval * 4 * 8  // 8
    ] @=> Time.bpmIntervalsLong;

    bpmInterval::second => Time.beatDur;
    Time.beatDur * 4 => Time.barDur;
    ( bpmInterval * Config.srate ) $ int => Time.beatLength;
    ( Time.beatLength * 4 ) => Time.barLength;
}

setTimeData();
