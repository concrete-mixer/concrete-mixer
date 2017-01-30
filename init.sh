#    Concrète Mixer - an ambient sound jukebox for the Raspberry Pi
#
#    Copyright (c) 2014-2016 Stuart McDonald  All rights reserved.
#        https://github.com/concrete-mixer/concrete-mixer
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
#    U.S.A.

#!/bin/bash

DAC=1

# Before kicking off Concrete Mixer we need to know if we're up for endless
# play mode. To do this extremely cheaply and cheerfully, awk concrete.conf
if [ ! -f ./concrete.conf ]
then
    echo "concrete.conf is not available. Please read README.md for instructions"
    exit
fi

# Here things get a bit awk-ward.
CHUCK_PATH=`awk 'match($0, /^chuckPath=.*$/) { print substr($0, 11) }' ./concrete.conf`
CHUGIN_PATH=`awk 'match($0, /^chuginPath=.*$/) { print substr($0, 12) }' ./concrete.conf`
BUFSIZE=`awk 'match($0, /^bufsize=[0-9]+$/) { print substr($0, 9) }' ./concrete.conf`
SRATE=`awk 'match($0, /^srate=[0-9]+$/) { print substr($0, 7) }' ./concrete.conf`
MODE=`awk 'match($0, /^mode=.+$/) { print substr($0, 6) }' ./concrete.conf`
DAC=`awk 'match($0, /^dac=.+$/) { print substr($0, 5) }' ./concrete.conf`

if [[ ! -x $CHUCK_PATH || ! -x $CHUGIN_PATH ]]
then
    # no custom chuck paths; default to linux ChucK build install paths
    CHUCK_PATH=/usr/local/bin/chuck
    CHUGIN_PATH=/usr/local/lib/chuck

    if [[ ! -x $CHUCK_PATH || ! -x $CHUGIN_PATH ]]
    then
        echo Chuck path or chugin path not available
        exit
    fi
fi


$EXEC_STRING=$CHUCK_PATH concrete.ck --chugin-path:$CHUGIN_PATH --srate:$SRATE --bufsize:$BUFSIZE --dac:$DAC

if [[ $MODE == 'soundcloud' ]]
then
    source venv/bin/activate
fi

# Else, run just the once.
echo "Running Concrete Mixer"

if [[ $MODE == 'soundcloud' ]]
then
    python soundcloud-fetch.py &
fi

$CHUCK_PATH concrete.ck --chugin-path:$CHUGIN_PATH --srate:$SRATE --bufsize:$BUFSIZE --dac:$DAC
