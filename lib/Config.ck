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

// This class defines stream data for playing lists of files
// from different directories
class StreamData {
    string streamsAvailable[0];
    string filePaths[0];
    string files[0][0];
    string things[];
    string mode;

    int concurrentSounds[0];

    fun void setStream(string stream) {
        streamsAvailable << stream;
        string audioFiles[0];
        audioFiles @=> files[stream];
    }

    fun void setFilePath(string stream, string path) {
        path => filePaths[stream];
    }

    fun void setFiles(string stream, string audioFiles[]) {
        audioFiles @=> files[stream];
    }

    fun void setFile(string stream, string file) {
        if ( ! files[stream].size() ) {
            string audioFiles[0];
            audioFiles @=> files[stream];
        }

        files[stream] << file;
    }

    fun void setConcurrentSounds(string stream, int num) {
        num => concurrentSounds[stream];
    }

    fun int getTotalConcurrentSounds() {
        int total;

        for ( int i; i < streamsAvailable.cap(); i++ ) {
            streamsAvailable[i] => string stream;
            concurrentSounds[stream] + total => total;
        }

        return total;
    }

    fun void setMode(string modeIn) {
        modeIn => mode;
    }
}

public class Config {
    static StreamData @ streamData;
    static int debug;
    static float bpm;
    static int bufsize;
    static int endlessPlay;
    static int fxChainEnabled;
    static int record;
    static int rpi;
    static int srate;
    static int ended;
    static int fxUsed[];
    static int sndBufChunks;
    static int oscWeb;
    static int oscWebPort;
}

class ConfigSet {
    fun void initialise() {
        _setDefaultValues();
        _setValuesFromConfig();
    }

    // initialise values with defaults
    fun void _setDefaultValues() {
        new StreamData @=> Config.streamData;
        "soundcloud" => Config.streamData.setMode;
        0 => Config.debug;
        90 => Config.bpm;
        2048 => Config.bufsize;
        0 => Config.endlessPlay;
        1 => Config.fxChainEnabled;
        0 => Config.record;
        0 => Config.rpi;
        44100 => Config.srate;
        512 => Config.sndBufChunks;
        0 => Config.oscWeb;
        0 => Config.oscWebPort;
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
                    _setValue(matches[1], matches[2]);
                }
            }
        }

        file.close();
    }

    fun void _setValue(string key, string stringValue) {
        int intValue;

        // Format value correctly
        // it would be nice if ChucK had switch statements
        if ( key == "bpm" ) {
            Std.atof(stringValue) => Config.bpm;
            return;
        }
        else {
            Std.atoi(stringValue) => intValue;
        }

        if ( key == "mode" ) {
            stringValue => Config.streamData.setMode;
        }

        if ( key == "debug" ) {
            intValue => Config.debug;
        }

        // now determine key to set and set
        // first, the ints
        if ( key == "srate" ) {
            intValue => Config.srate;
            return;
        }

        if ( key == "record" ) {
            intValue => Config.record;
            return;
        }

        if ( key == "rpi" ) {
            intValue => Config.rpi;
            return;
        }

        if ( key == "fxChainEnabled" ) {
            intValue => Config.fxChainEnabled;
            return;
        }

        if ( key == "endlessPlay" ) {
            intValue => Config.endlessPlay;
            return;
        }

        if ( key == "sndBufChunks" ) {
            intValue => Config.sndBufChunks;
            return;
        }

        if ( key == "oscWeb" ) {
            intValue => Config.oscWeb;
        }

        if ( key == "oscWebPort" ) {
            intValue => Config.oscWebPort;
        }

        // finally, audio sources

        // we default to soundcloud
        string matches[0];

        RegEx.match("^stream([0-9]+)Url", key, matches);

        if ( matches.size() ) {
            matches[1] => string stream;
            stream => Config.streamData.setStream;
            return;
        }

        // if not soundcloud, then we get audio from local directories...
        // reset matches
        0 => matches.size;

        RegEx.match("^stream([0-9]+)Path", key, matches);

        if ( matches.size() ) {
            matches[1] => string stream;
            stream => Config.streamData.setStream;
            Config.streamData.setFilePath(stream, stringValue);
            Config.streamData.setFiles(stream, _setFiles(stringValue));
            return;
        }

        // get concurrentsounds value for each stream
        0 => matches.size;

        RegEx.match("^stream([0-9]+)ConcurrentSounds", key, matches);

        if ( matches.size() ) {
            matches[1] => string stream;
            Std.atoi(stringValue) => intValue;
            Config.streamData.setConcurrentSounds(stream, intValue);
        }
    }

    fun string[] _setFiles(string path) {
        FileIO fileList;

        fileList.open(path);

        _processFileList( fileList.dirList(), path ) @=> string files[];

        fileList.close();

        return files;
    }

    fun string[] _processFileList( string fileList[], string path ) {
        string soundsFound[0];

        for ( 0 => int i; i < fileList.cap(); i++ ) {
            if ( RegEx.match(".(wav|aif|aiff)$", fileList[i]) ) {
                soundsFound << path + "/" + fileList[i];
            }
        }

        return soundsFound;
    }
}

ConfigSet setup;

setup.initialise();
