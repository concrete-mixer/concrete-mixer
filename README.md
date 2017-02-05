# Concrète Mixer

## About

Concrète Mixer is an program that mixes and scrambles a set of sound recordings in interesting ways. The name is a pun on [musique concrète](https://en.wikipedia.org/wiki/Musique_concr%C3%A8te).

Concrète Mixer is designed to be run on a [Raspberry Pi](https://www.raspberrypi.org/). You can either run Concrète Mixer:
- through an rpi's audio out into a mixer or stereo amplifier
- in a [Docker container](https://github.com/concrete-mixer/cm-rpi-docker-icecast) which will provide an [Icecast](https://icecast.org) mp3 stream suitable for internet radio broadcasting.

Concrète Mixer can play audio files stored locally or downloaded them from a [SoundCloud](https://soundcloud.com) playlist.

### What does it sound like?

Have a listen to an [hour long demo](https://concrete-mixer.bandcamp.com). This demo consists of two renderings of the app with the same set of sounds. The demo tracks are presented 'as-is' with no post-processing or editing.

### What's it written in?

The audio processing is written in [ChucK](http://chuck.cs.princeton.edu). A small shell script is used to initiate playback. SoundCloud playlist download is facilitated with a python script.

## Prerequisites

Concrète Mixer is intended for use on the latest model of Raspberry Pi (currently Raspberry Pi 3) running [Rasbpian](https://www.raspbian.org/) GNU/Linux (currently version 'Jessie'). It can run on other hardware and operating systems with a bit of extra configuration but this documentation is focussed on Raspbian support only.

## Installation

Concrète Mixer is a relatively simple program but has a lot of software dependencies and fiddly configuration. The easiest way to get up and running is to install one of the Concrète Mixer docker images.

### Install for evaluation via git checkout

This is the best option with ChucK-savvy users who want to check Concrète Mixer out on a pi:

1. Clone the Concrète Mixer repo:

    `git clone https://github.com/concrete-mixer/concrete-mixer`

2. Enter the repo directory:

    `cd concrete-mixer`

3. Copy concrete.conf.sample to concrete.conf:

    `cp concrete.conf.sample concrete.conf`

4. Run ./pi-install.sh to install various packages (note that it's probably easier to use a Docker image; see below.)

4. Run init.sh

    `./init.sh`

5. `concrete.conf.sample` is set up to source a couple of SoundCloud playlists for audio. If you want to use your own sounds on the pi or from another SoundCloud playlist, you can modify `config.conf` to suit.


### Concrète Mixing machine via docker

There's a [Docker image](https://github.com/concrete-mixer/cm-rpi-docker-dac) which installs Concrete Mixer and its dependencies automatically.


### Creating a Concrète Mixing internet radio station

If you'd like to operate Concrète Mixer as a radio station, there's a [Docker image](https://github.com/concrete-mixer/cm-rpi-docker-internet) that marries up Concrète Mixer with Darkice and Icecast2 to provide an internet radio stream.


## Customising configuration options

A list of configuration options is documented in `concrete.conf.sample`.


### SoundCloud support

Concrète Mixer will download sound files from SoundCloud playlists as long the files are made downloadable (this can be configured in the `permissions` tab when you upload a sound.

If not already compatible, downloaded files will be converted to wav so that ChucK can use them). The conversion process makes use of the [FFmpeg](https://ffmpeg.org) library, so any audio format that FFmpeg can convert should be acceptable. The following compressed formats are known to work:
- mp3
- ogg
- aac
- flac

Compressed lossless audio (eg flac) is the optimal format having the best fidelity with a (relatively) small file size. In practice though whatever works for you is fine. Note that converting some formats may have a greater performance penality than others.


## The art of Concrèting

* Concrète Mixer was intended to mix field recordings of non-musical (or probably non musical) sounds together to create a surrealistic soundscape. However, the app could be used in other ways. For example, `concrete.conf` provides a tempo setting (`bpm`) which is used to define timings for things like LFO speeds, delay times, and fade times. You could potentially take musical recordings in a compatible tempo and key and mix them together.
* From experience sound files of about 90 seconds to two and a half minutes seem to work best in terms of the flow of the mix, but this will depend on the dynamics of the recording and (to a large degree) the taste of the listener.
* You should mix the samples' levels to be generally consistent so that any one sample should not be disproportionately louder than any other. I tend to mix these reasonably quietly as enloudened environmental sound can be a bit exasperating blaring out over speakers.
* You can specify several configuration options in the conf/concrete.conf file. Refer to `concrete.conf.sample` for more options.
    * If you're having performance difficulties you can enable the rpi setting by setting rpi=1 in `concrete.conf`. This setting utilises a less CPU-intensive reverb ugen and also refrains from using a reverse delay chugen. The author can run CM on an rpi3 without needing this setting, but earlier models will require it.
* The Pi's analogue audio output is noisy; better sound may be obtained by:
    * routing digital audio through HDMI (run `raspi-config` > `Advanced options` > `Audio` to achieve this), and using an HDMI adapter with an audio out (preferably powered); or
    * using a USB sound card.

## Licence

This code is distributed under the GPL v2. See the COPYING file for more details.

## Contact
<concretemixer.audio@gmail.com>
