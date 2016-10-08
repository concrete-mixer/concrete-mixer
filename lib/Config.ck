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

// The following is a whack way of supporting static strings, see:
// https://lists.cs.princeton.edu/pipermail/chuck-users/2006-September/001107.html
class FilePath {
    string path;
}

public class Config {
    static string altFiles[];
    static FilePath @ audioAltPath;
    static FilePath @ audioMainPath;
    static float bpm;
    static int bufsize;
    static int concurrentSounds;
    static int endlessPlay;
    static int fxChainEnabled;
    static string mainFiles[];
    static int record;
    static int rpi;
    static int srate;
    static int ended;
}

class ConfigSet {
    fun void initialise() {
        _setDefaultValues();
        _setValuesFromConfig();

        _setFileLists("main");
        _setFileLists("alt");
    }

    // initialise values with defaults
    fun void _setDefaultValues() {
        new FilePath @=> Config.audioAltPath;
        "" => Config.audioAltPath.path;
        new FilePath @=> Config.audioMainPath;
        "" => Config.audioMainPath.path;
        90 => Config.bpm;
        2048 => Config.bufsize;
        2 => Config.concurrentSounds;
        0 => Config.endlessPlay;
        1 => Config.fxChainEnabled;
        0 => Config.record;
        0 => Config.rpi;
        44100 => Config.srate;
    }

    fun void _setValuesFromConfig() {
        FileIO file;

        file.open("concrete.conf", FileIO.READ);

        while ( ! file.eof() ) {
            file.readLine() => string line;

            if ( line != "" && line.substring(0, 1) != "#" ) {
                string matches[0];

                RegEx.match("^(.*)=(.*)$", line, matches);

                if ( matches.cap() ) {
                    for( 0 => int i; i < matches.cap(); i++ ) {
                        _setValue(matches[1], matches[2]);
                    }
                }
            }
        }

        file.close();
    }

    fun void _setValue(string key, string stringValue) {
        int intValue;

        // format value correctly
        if ( key != "audioMainPath" && key != "audioAltPath" ) {
            if ( key == "bpm" ) {
                Std.atof(stringValue) => Config.bpm;
            }
            else {
                Std.atoi(stringValue) => intValue;
            }
        }

        // now determine key to set and set
        // first, the ints
        if ( key == "srate" ) {
            intValue => Config.srate;
        }

        if ( key == "record" ) {
            intValue => Config.record;
        }

        if ( key == "rpi" ) {
            intValue => Config.rpi;
        }

        if ( key == "fxChainEnabled" ) {
            intValue => Config.fxChainEnabled;
        }

        if ( key == "concurrentSounds" ) {
            intValue => Config.concurrentSounds;
        }

        if ( key == "endlessPlay" ) {
            intValue => Config.endlessPlay;
        }

        // finally, audio path strings
        if ( key == "audioMainPath" ) {
            new FilePath @=> Config.audioMainPath;
            stringValue @=> Config.audioMainPath.path;
        }

        if ( key == "audioAltPath" ) {
            new FilePath @=> Config.audioAltPath;
            stringValue @=> Config.audioAltPath.path;
        }
    }

    fun void _setFileLists(string type) {
        FileIO fileList;

        if ( type == "main" ) {
            fileList.open(Config.audioMainPath.path);
            _processFileList( fileList.dirList() ) @=> Config.mainFiles;
        }

        if ( type == "alt" && Config.audioAltPath.path != "" ) {
            fileList.open(Config.audioAltPath.path);
            _processFileList( fileList.dirList() ) @=> Config.altFiles;
        }

        fileList.close();
    }

    fun string[] _processFileList( string fileList[] ) {
        string wavsFound[0];

        for ( 0 => int i; i < fileList.cap(); i++ ) {
            if ( RegEx.match(".wav$", fileList[i]) ) {
                wavsFound << fileList[i];
            }
        }

        return wavsFound;
    }

    fun void printFileList(string type) {
        string target[];

        chout <= type <= IO.nl();

        if ( type == "main" ) {
            Config.mainFiles @=> target;
        }

        if ( type == "alt" ) {
            Config.altFiles @=> target;
        }

        for ( 0 => int i; i < target.cap(); i++ ) {
            chout <= target[i] <= IO.nl();
        }
    }

    fun void printVars() {
        1 => int i;

        <<< i++, Config.audioAltPath.path >>>;
        <<< i++, Config.audioMainPath.path >>>;
        <<< i++, Config.bpm >>>;
        <<< i++, Config.bufsize >>>;
        <<< i++, Config.concurrentSounds >>>;
        <<< i++, Config.endlessPlay >>>;
        <<< i++, Config.fxChainEnabled >>>;
        <<< i++, Config.record >>>;
        <<< i++, Config.rpi >>>;
        <<< i++, Config.srate >>>;
    }
}

ConfigSet setup;

setup.initialise();

// setup.printVars();
//
// setup.printFileList("main");
// setup.printFileList("alt");
