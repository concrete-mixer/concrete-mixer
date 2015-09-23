#    Concrète Mixer - an ambient sound jukebox for the Raspberry Pi
#
#    Copyright (c) 2014 Stuart McDonald  All rights reserved.
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

package ConcreteMixer::Concrete;
use base ConcreteMixer::Mode;
use strict;
use warnings;
use 5.10.0;
use List::Util;
use Data::Dump qw(dump);
my $data = {};

sub new {
    my ( $class, $config ) = @_;
    my $self = {};
    bless $self, $class;
    $self->{config} = $config;

    # do a bit of dying if config is nonsensical
    die "concurrent_sounds value not specified" if not $config->{concurrent_sounds};
    die "audio_main_path not specified" if not $config->{audio_main_path};

    if ( $config->{audio_alt_path} and $config->{concurrent_sounds} == 1 ) {
        $config->{concurrent_sounds} = 2;
        say "Setting concurrent_sounds to 2 as audio_alt_path specified";
    }

    $self->{play_files_main} = $self->get_files_list( $config->{audio_main_path} );

    die 'No main files present' if not scalar @{ $self->{play_files_main} };

    if ( $config->{audio_alt_path} ) {
        $self->{play_files_alt} = $self->get_files_list( $config->{audio_alt_path} );
        die 'No alt files present' if not scalar @{ $self->{play_files_alt} };
    }

    $self->{libpath} = 'lib/Modes/Concrete';
    $self->{fxChains} = $self->build_fxchains;
    $self->{playing_count} = 0;

    my $count = 0;

    while ( $count < $config->{concurrent_sounds} ) {
        $count++;

        if ( $self->{play_files_alt} and $count == $config->{concurrent_sounds} ) {
            $self->play_sound( 'alt' );
            next;
        }

        $self->play_sound;
    }

    if ( $config->{fx_chain_enabled} ) {
        my $fxChain = $self->get_fxchain;
        system( "$config->{chuck_path} + $self->{libpath}/playFxChain.ck:$fxChain" );
    }

    $data = $self;
    return $self;
}

# the OSC server callback
# processes messages back from playSound.ck and playFx.ck and respawns
# those processes until no sounds are left to play
sub process_osc_notifications {
    my ( $sender, $message ) = @_;
    my $self = $data;

    # first consider if we should serve the request or if there's
    # * a memory usage issue requiring process to end
    # * no more sounds to play and the last sound has finished playing
    if (
        $self->end_check # check for excess memory use
        # or if there's no sounds left to play
        or ( not $self->sounds_left and not $self->{playing_count} )
    ) {
        # don't do whatever you were going to do, fade out and either
        # end or reinitialise program
        $self->fade_mix;
    }

    # if we aren't already in a restart process or we've
    # discovered we need to kick off a restart process, carry on...
    if ( $message->[0] eq 'playSound' ) {
        my $type = $message->[2]; # should be 'main' or 'alt

        # decrement playing count as we know file has finished playing
        $self->{playing_count}--;

        if ( $self->sounds_left ) {
            $self->play_sound( $type );
        }
        else {
            $self->fade_mix;
        }
    }

    if ( $message->[0] eq 'playFxChain' ) {
        print "Got playFxChain notification, regenerating\n";
        my $fxChain = $self->get_fxchain;
        system( qq{$self->{config}{chuck_path} + $self->{libpath}/playFxChain.ck:$fxChain});
    }

    if ( $message->[0] eq 'fadeOutComplete' ) {
        $self->end;
    }
}

sub sounds_left {
    my ( $self ) = @_;

    # determine how many files are left
    my $count = scalar @{ $self->{play_files_main} };

    if ( defined $self->{play_files_alt} and scalar @{ $self->{play_files_alt} } ) {
        $count += scalar @{ $self->{play_files_alt} };
    };

    return $count;
}

sub end {
    my ( $self ) = @_;

    if ( $self->{config}{endless_play} ) {
        say "REINITIALISING\n";
        $self->reinitialise();
    }
    else {
        $self->kill_master_pid();
        say "EXITING";
        exit;
    }
}

=head2

playFx isn't playSound-aware, so when we run out of sounds we need to shut down the app manually.

This function invokes fadeMix, which zeroes the playback volume, and reports back via OSC, at which point we shut down or restart chuck.

=cut
sub fade_mix {
    my ( $self ) = @_;
    system( qq{$self->{config}{chuck_path} + $self->{libpath}/fadeMix.ck});
}

=head2 build_fxchains

Builds an random array of fx ids for use by playFx.ck. Once
the array is emptied of fx patches it gets rebuilt.

The point of doing it like this that we don't reuse an fxchain
until we've used all the others, meaning less repetition overall.

=cut
sub build_fxchains {
    my $self = shift;
    my @arr;

    # there are some fx we don't want rpis to use as they use chugens.
    # It's unfortunate we have to hardcode things here but then the
    # whole business of using Perl to bootstrap Chuck is unfortunate.
    if ( $self->{config}{rpi} ) {
        @arr = ( 1..19 );
    }
    else {
        @arr = ( 1..25 );
    }

    @arr = List::Util::shuffle @arr;

    return \@arr;
}

sub get_fxchain {
    my $self = shift;

    if ( not scalar @{ $self->{fxChains} } ) {
        $self->{fxChains} = $self->build_fxchains;
    }

    return pop @{ $self->{fxChains} };
}

sub play_sound {
    my ( $self, $type) = @_;

    $type //= 'main';

    chdir $self->{config}{cwd};
    my $filename;

    # get file to play
    # in the normal run of things, play_sound only gets called
    # when we know there's at least one file to play
    if ( $type eq 'alt' ) {
        $filename = pop @{ $self->{play_files_alt} };

        # if we've run out of files, try the 'main' pool
        if ( not $filename ) {
            $self->play_sound;
            return;
        }
    }
    else {
        $filename = pop @{ $self->{play_files_main} };

        # if we've run out of files, try the 'alt' pool
        if ( not $filename ) {
            $self->play_sound('alt');
            return;
        }
    }


    print "playSound playing $filename\n";
    my $command = "$self->{config}{chuck_path} + $self->{libpath}/playSound.ck:" . '"' . $filename . '"';

    if ( $type eq 'alt' ) {
        $command .= ":alt";
    }

    system( $command );
    $self->{playing_count}++;
}

1;
