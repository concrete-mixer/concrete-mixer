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

public class SoundFiles {
    static string main[];
    static string alt[];

    _setFileLists("main");
    _setFileLists("alt");

    fun void _setFileLists(string type) {
        FileIO fileList;

        if ( type == "main" ) {
            fileList.open(Config.audioMainPath.path);
            _processFileList( fileList.dirList() ) @=> main;
        }

        if ( type == "alt" && Config.audioAltPath.path != "" ) {
            fileList.open(Config.audioAltPath.path);
            _processFileList( fileList.dirList() ) @=> alt;
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
            main @=> target;
        }

        if ( type == "alt" ) {
            alt @=> target;
        }

        for ( 0 => int i; i < target.cap(); i++ ) {
            chout <= target[i] <= IO.nl();
        }
    }
}
