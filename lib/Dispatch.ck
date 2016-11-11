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


class Dispatch {
    0 => int fxMachineId;
    0 => int ending;
    int streamsActive[0];
    Fader f;

    fun void initialise() {
        0 => int altSent;

        if ( Config.mainFiles.size() == 0 ) {
            me.exit();
        }

        streamsActive.size(Config.concurrentSounds);

        for ( 0 => int i; i < Config.concurrentSounds; i++ ) {
            string filePath;

            if ( Config.altFiles.size() && ! altSent ) {
                1 => altSent;
                playSound("alt", i);
            }
            else {
                playSound("main", i);
            }

            1 => streamsActive[i];
        }

        if ( Config.fxChainEnabled ) {
            // keep track of the machine id for fx chain so we can scupper it
            // when file playback is complete.
            Machine.add(me.dir() + "../playFxChain.ck") => fxMachineId;
        }

        OscIn oin;
        3141 => oin.port;

        "/playsound/alt" => oin.addAddress;
        "/playsound/main" => oin.addAddress;
        "/playsound/streamlength" => oin.addAddress;
        "/playfxchain" => oin.addAddress;

        OscMsg msg;

        // start listening for packets notifying server that playback
        // for each playFx and playSound has finished
        while ( true ) {
            oin => now;

            while(oin.recv(msg)) {
                // stream is always the first args if there are args
                msg.getInt(0) => int stream;

                chout <= "Received " <= msg.address <= IO.nl();

                if ( msg.address == "/playsound/alt" ) {
                    playSound("alt", stream);
                }

                if ( msg.address == "/playsound/main" ) {
                    playSound("main", stream);
                }

                if ( msg.address == "/playfxchain" ) {
                    Machine.add(me.dir() + "../playFxChain.ck") => fxMachineId;
                }
            }
        }
    }

    fun string getFileToPlay(string type) {
        // set up our vars
        string target[];
        string file, filePath;

        if ( type == "alt" ) {
            Config.altFiles @=> target;
            Config.audioAltPath.path => filePath;
        }
        else {
            Config.mainFiles @=> target;
            Config.audioMainPath.path => filePath;
        }

        // if target array empty return empty string
        // means playSound.ck won't be invoked
        if ( ! target.size() ) {
            return "";
        }

        Math.random2(0, target.size() - 1) => int key;

        target[key] => file;

        removeFile(key, type);

        return filePath + "/" + file;
    }

    fun void removeFile(int key, string type) {
        // because ChucK is fucking primitive, we can't remove items from
        // an array - we have to reconstruct it
        string target[];
        string file, filePath;

        if ( type == "alt" ) {
            Config.altFiles @=> target;
        }
        else {
            Config.mainFiles @=> target;
        }

        target.size() => int size;
        string newArray[0];

        for ( int i; i < size; i++ ) {
            if ( i != key ) {
                newArray << target[i];
            }
        }

        if ( type == "alt" ) {
            newArray @=> Config.altFiles;
        }
        else {
            newArray @=> Config.mainFiles;
        }
    }

    fun int playSound( string type, int stream ) {
        getFileToPlay(type) => string filePath;

        if ( filePath != "" ) {
            me.dir() + "../playSound.ck:" + filePath + ":" + type + ":" + stream => string args;

            Machine.add(args);
        }
        else {
            0 => streamsActive[stream];

            if ( lastStream(stream) ) {
                endActivity();
            }
        }
    }

    fun int lastStream(int stream) {
        1 => int streamIsLast;

        // Determine if any streams are still active
        for ( int i; i < streamsActive.size(); i++ ) {
            if ( streamsActive[i] ) {
                // there is another stream still active
                // so return false
                0 => streamIsLast;
            }
        }

        return streamIsLast;
    }

    fun void endActivity() {
        2 * Time.barDur => dur fadeDur;

        // 2. Start fade
        f.fadeOut(fadeDur, Mixer.leftOut);
        f.fadeOut(fadeDur, Mixer.rightOut);

        // If a playFxChain still running, remove it
        Machine.remove(fxMachineId);

        1 => Config.ended;

        <<< "Dispatcher signing out" >>>;

        me.exit();
    }
}

Dispatch dispatch;

dispatch.initialise();
