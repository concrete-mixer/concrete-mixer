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
    Class providing functions to derive random values
*/
public class Chooser {
    /*
        takeAction returns true based on random choice
        Takes argument denominator, which is the end limit of the range of numbers
        a random value is chosen from.

        The function only returns true (1) if the random value chosen is 1. Therefore
        the denominator defines how often we expect to get a non zero result. This
        enables us to fine tune the frequency of activity from different sound
        manipulations.
    */
    fun static int takeAction(int denominator) {
        // plan here is to return 1 (true, do something, 10% of the time)
        Math.random2(1,denominator) => int choice;

        if ( choice == 1 ) {
            return 1;
        }

        return 0;
    }

    // wait just calls getDur; it's defined to disambiguate
    // calls for the purpose of determining durations of idleness
    // vs calls made to get a dur to do something with
    fun static dur getWait( float min, float max ) {
        return getDur( min, max );
    }

    fun static dur getDur( float min, float max ) {
        return Math.random2f( min, max )::second;
    }

    // takes care of generating random floats, which we seem
    // to need a lot of
    fun static float getFloat( float min, float max ) {
        return Std.rand2f( min, max );
    }

    fun static int getInt( int min, int max ) {
        return Math.random2( min, max );
    }

    fun string[] selectFiles( string inputFiles[], int targetCount ) {
        string outputFiles[ targetCount ];
        int choices[ targetCount ];
        0 => int selectionsCount;

        while ( selectionsCount < targetCount ) {
            getInt( 0, inputFiles.cap() - 1 ) => int choice;
            0 => int alreadyChosen;

            for ( 0 => int j; j < choices.cap() - 1; j++ ) {
                // <<< "j", j, choices[j] >>>;
                if ( choices[j] == choice ) {
                    // <<< choice, "already chosen" >>>;
                    1 => alreadyChosen;
                }
            }

            if ( ! alreadyChosen ) {
                inputFiles[choice] => outputFiles[ selectionsCount ];
                choice => choices[ selectionsCount ];
                selectionsCount++;
            }

        }
        return outputFiles;
    }

    fun float getIntervalLong() {
        getInt( 0, Control.bpmIntervalsLong.cap() - 1 ) => int choice;

        return Control.bpmIntervalsLong[ choice ];
    }

    fun float getIntervalShort() {
        getInt( 0, Control.bpmIntervalsShort.cap() - 1 ) => int choice;

        return Control.bpmIntervalsShort[ choice ];
    }
}
