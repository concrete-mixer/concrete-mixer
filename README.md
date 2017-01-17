# Concrète Mixer

## About

Concrète Mixer is an ambient jukebox program. What this means is if you supply the software with a set of sound files, it will mix and scramble the sounds in interesting ways.

You can supply any soundfiles, but Concrète Mixer was intended for blending two or more field recordings or found sounds together, typically records of a minute to two minutes' length.

Concrète Mixer is designed to be run on a [Raspberry Pi](https://www.raspberrypi.org/). When a Pi is hooked up to loudspeakers your sounds can haunt any space of your choosing.

### What does it sound like?

Have a listen to an [hour long demo](https://concrete-mixer.bandcamp.com). This demo consists of two renderings of the app with the same set of sounds. The demo tracks are presented 'as-is' with no post-processing or editing.

### What's it written in?

The audio processing is written in [ChucK](http://chuck.cs.princeton.edu). A small shell script is used to initiate playback. Soundcloud playlist download is facilitated with a python script.

## Prerequisites

Concrète Mixer is intended for use on the latest model of Raspberry Pi (currently Raspberry Pi 3) running [Rasbpian](https://www.raspbian.org/) GNU/Linux. Earlier Pi models *may* work with overclocking and special configuration settings applied. (In principle though, Concrète Mixer will run on any OSes and devices on which ChucK will run. YMMV.)

Basic familiarity with running shell commands in linux, as well as installing and configuring Raspbian is required.

## Installation

The following procedure will get you up and running with Concrete Mixer on a Raspbery Pi.

1. Ensure your Raspbian system packages are up to date:

    `sudo apt update && sudo apt upgrade && sudo apt-get install git`

    (Note apt commands may take a while to run on a pi)

2. Clone the Concrete Mixer repo:

    `git clone https://github.com/concrete-mixer/concrete-mixer`

3. Run the pi-install.sh script:

    `cd concrete-mixer && sudo ./pi-install.sh`

4. Cross your fingers.

4. All going well, the pi-install.sh file will start Concrete Mixer. To run it manually, type:

    `./init.sh`

### Not using a Pi?

For non Raspberry Pi installations, inspect pi-install.sh and make the equivalent changes for your system until you can run `./init.sh`. This should be fairly straightforward for those with Debian-derived Linuxes. For other linuxes and unices (including MacOS) there will be equivalent packages available for the prerequisites.

### Making a Raspberry Pi an automatic Concrète Mixer

The intention of Concrète Mixer is to turn a Pi into a single-purpose sound machine that runs the app indefinitely from boot without any supervision. You don't have to run Concrete Mixer like this, but if you'd like to, here's what you do:

#### 1. Prep system to autologin pi user on tty1

Some versions of Raspbian use initd and some use systemd, so here's procedures for either:

##### Raspbian with systemd

1. Create file `/etc/systemd/system/getty@tty1.service.d/concrete-mixer.conf` with your favourite editor (here we use nano):

    `sudo nano /etc/systemd/system/getty@tty1.service.d/concrete-mixer.conf`

2. Enter the following lines:

    ```bash
    [Service]
    ExecStart=
    ExecStart=-/sbin/agetty --autologin pi --noclear %I 38400 linux
    ```

3. Save the file. You should now be able to autologin the pi user. The next step is to add lines to /home/pi/.bashrc


##### Raspbian with inittab

1. Edit conf/concrete.conf and set ``endlessPlay=1``. This will restart the app when it runs out of files to play.
2. To run Concrète Mixer each time the Pi is started, edit ``/etc/inittab`` using your favorite editor (here assuming nano):
    ``sudo nano /etc/inittab``
3. Search for the line ``1:2345:respawn:/sbin/getty 115200 tty1`` and comment it out by adding a ``#`` character at the start of line.
4. Add the following code beneath the commented out line: ``1:2345:respawn:/bin/login -f pi tty1 </dev/tty1 >/dev/tty1 2>&1``
5. Save the file. You should now be able to autologin the pi user. The next step is to add lines to /home/pi/.bashrc


#### 2. Add lines to ~/.bashrc

1. To get the pi user running Concrète Mixer automatically on tty1, edit /home/pi/.bashrc:
    ``nano /home/pi/.bashrc``.

2. At the bottom of the file, add the following lines:

    ```
    if [ $(tty) == /dev/tty1 ]; then
        cd ~/concrete-mixer
        ./init.sh
    fi
    ```

    This code will invoke Concrète Mixer if the current terminal is tty1. This means you can run the program in one terminal and use other terminals as required.

3. Save the file and restart the Pi. All going well, the Pi should start playing sound automatically after reboot.


## Configuration options

A list of configuration options is documented in concrete.conf.sample.

## The art of Concrèting

* From experience sound files of about 90 seconds to two and a half minutes seem to work best in terms of the flow of the mix, but this will depend on the dynamics of the recording and (to a large degree) the taste of the listener.
* You should mix the samples' levels to be generally consistent so that any one sample should not be disproportionately louder than any other.
* You can specify several configuration options in the conf/concrete.conf file. Refer to `concrete.conf.sample` for more options.
    * If you're having performance difficulties you can enable the rpi setting by setting rpi=1 in `concrete.conf`. This setting utilises a less CPU-intensive reverb ugen and also refrains from using a reverse delay chugen. The author can run CM on an rpi3 without needing this setting, but earlier models will require it.
* The Pi's analogue audio output is noisy; better sound may be obtained by:
    * routing digital audio through HDMI (run `raspi-config` > `Advanced options` > `Audio` to achieve this), and using an HDMI adapter with an audio out (preferably powered)
    * installing and using a USB sound card.

## Licence

This code is distributed under the GPL v2. See the COPYING file for more details.

## Contact
<concretemixer.audio@gmail.com>
