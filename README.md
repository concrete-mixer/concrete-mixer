# Concrète Mixer

## About

Concrète Mixer is an ambient jukebox program. What does this mean? If you supply the software with a set of sound files, it will mix them together and apply effects to them. Each rendering of sounds is unique.

Concrète Mixer is designed to be run on a [Raspberry Pi](https://www.raspberrypi.org/). When a Pi is hooked up to loudspeakers your sounds can haunt any space of your choosing.

### What does it sound like?

Have a listen to an [hour long demo](https://concrete-mixer.bandcamp.com). This demo consists of two renderings of the app with the same set of sounds. The demo tracks are presented 'as-is' with no post-processing or editing. If you'd like to make use of the sound recordings used in the demo, or compare the raw files to how they sound rendered, you can [download them](https://s3-us-west-1.amazonaws.com/concrete-mixer/concrete-mixer-files.zip).

### What's it written in?

The audio processing is written in [ChucK](http://chuck.cs.princeton.edu). A [Perl](http://www.perl.org) script (with supporting libraries) takes care of the execution and process restarts.

## Prerequisites

Concrète Mixer is intended for use on a Raspberry Pi 2 Model B running [Rasbpian](https://www.raspbian.org/). (Earlier Pi models *may* work with overclocking and special configuration settings applied.) In principle though, Concrète Mixer will run on any OSes/devices on which Perl and ChucK are available.

Finally, basic familiarity with running shell commands in linux is required.

## Installation and operation

1. The first thing you'll need is a set of sound files you want the software to mix. If you don't yet have a collection of sound files, you can [use the Concrète Mixer demo files](https://s3-us-west-1.amazonaws.com/concrete-mixer/concrete-mixer-files.zip). See [Tips](#tips) regarding using your own sound files.

2. Visit the [Concrète Mixer GitHub page](https://github.com/concrete-mixer/concrete-mixer) and click the [Download ZIP](https://github.com/concrete-mixer/concrete-mixer/archive/master.zip) link.
3. Unzip the code:
``$ unzip concrete-mixer-master.zip``
4. After unzipping you should have a directory called 'concrete-mixer-master'. Enter that directory and run the following commands to set up the config files:
``$ cp conf/global.conf.sample conf/global.conf``
``$ cp conf/concrete.conf.sample conf/concrete.conf``

5. Edit conf/concrete.conf and specify a directory location for your sounds:
``concurrent_sounds_main_path=<insert your dir here>``
Note that you can also supply a path for a second directory (concurrent_sounds_alt_path) for sounds that you don't want to be played against each other; instead these sounds will be mixed with the 'main' sounds.

6. It's nearly time to start the app. Before you can do so, however, you need to make a Perl environment setting:
``$ export PERL5LIB=.:perllib``
To make this permanent, run:
``$ echo export PERL5LIB=.:perllib >> ~/.bashrc``
(This assumes that you're using bash as your shell.)

7. Run the app typing the following from your app's directory:
``./init.pl``

### Making a Raspberry Pi into a Concrète Mixer

The intention of Concrète Mixer is to turn a Pi into a single-purpose sound machine that may be left to run without any supervision indefinitely. You don't have to do this, but if you'd like to, here's what you do:

1. Edit conf/concrete.conf and set ``endless_play=1``. This will restart the app when it runs out of files to play.
2. To run Concrète Mixer each time the Pi is started, edit ``/etc/inittab`` using your favorite editor (here assuming nano):
    ``sudo nano /etc/inittab``
    Enter your password if required.
3. Search for the line ``1:2345:respawn:/sbin/getty 115200 tty1`` and comment it out by adding a ``#`` character at the start of line.
4. Add the following code beneath the commented out line: ``1:2345:respawn:/bin/login -f pi tty1 </dev/tty1 >/dev/tty1 2>&1``

    This line sets tty1 (the system's terminal number 1) to log in the pi user automatically on boot.

5. To get the Pi to run Concrète Mixer automatically, edit /home/pi/.bashrc:
    ``nano /home/pi/.bashrc``.

6. At the bottom of the file, add the following lines:
<code>
    export PERL5LIB=<insert your path to concrete mixer dir here>/perllib
    if [ $(tty) == /dev/tty1 ]; then
        cd ~/concrete-mixer
        perl init.pl
    fi
</code>
The first line sets the $PERL5LIB environment variable automatically (mentioned above). The subsequent lines invoke Concrète Mixer if the current terminal is tty1 only. This means you can run the program in one terminal and can perform other tasks in other terminals.

7. Save the file and restart the Pi. All going well, the Pi should start playing sound automatically after reboot.

## General discussion

### <a name="tips">Tips
* From experience sound files of about 90 seconds to two and a half minutes seem to work best in terms of the flow of the mix, but this will depend on the dynamics of the recording and (to a large degree) the taste of the listener.
* You should mix the samples' levels to be generally consistent so that any one sample should not be disproportionately louder than any other.
* You can specify several configuration options in the conf/concrete.conf file. Read concrete.conf.sample for more options.
* The Pi's analogue audio output is noisy; if possible use an HDMI audio splitter (preferably powered), or a USB sound card.
* The chuck executable file distributed with Concrète Mixer was compiled on a Raspberry Pi 2 Model B. This binary *may not* work on earlier Pi Models as the Pi 2's CPU architecture is different.

#### Running Concrète Mixer on other devices

You should be able to run Concrète Mixer on OSX without much trouble; on Windows things will be much trickier.
* [Information on how to install ChucK on various platforms](http://chuck.cs.princeton.edu/release)
* [Information on how to install Perl on various platforms](http://www.perl.org/get.html)

Note that on other platforms the ChucK executable and chugin files included with Concrète Mixer will not work as it has been compiled for the Pi. To use Concrète Mixer on other platforms you'll need to change the conf/global.conf file to point to a different ChucK executable (read the config file for more details).

## Licence

This code is distributed under the GPL v2. See the COPYING file for more details. The ChucK binary is also GPL v2. The included Perl code is also GPL.

## Acknowledgments

* The [Chuck authors](http://chuck.cs.princeton.edu/doc/authors.html), especially for giving me their blessing to include the chuck binary with this program, since ChucK itself has no (up to date) Debian package.
* Christian Renz, who authored the [Net::OpenSoundControl](http://search.cpan.org/~crenz/Net-OpenSoundControl-0.05/lib/Net/OpenSoundControl.pm) Perl module
* Jonny Schulz, who authored the [Sys::Statistics::Linux](http://search.cpan.org/~bloonix/Sys-Statistics-Linux/lib/Sys/Statistics/Linux.pm) Perl module.

## Contact
<concretemixer.audio@gmail.com>
