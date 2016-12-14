import random
import re
import sys
import os, shutil
from multiprocessing import Pool

import requests
import pprint
import soundcloud
from pydub import AudioSegment
from pythonosc import udp_client, osc_message, osc_message_builder
import OSC


streams = []


filename = 'concrete.conf'
lines = open(filename, 'r').read().split('\n')

for line in lines:
    matches = re.match( r'^stream(\d+)Url=(.*)$', line )

    if ( matches ):
        stream = matches.group(1)
        streams.append({
                'stream': matches.group(1),
                'url': matches.group(2),
                'tmp_path': '/tmp/concreteMixerStream' + stream
                })

osc_client = OSC.OSCClient()

# this is Concrete Mixer's own app key so please use it nicely
client_id = '11bab725274cff587d5908c18cd501c2'



def download_stream_files(stream_data):
    # because of Soundcloud API's T&Cs we can't store files we download
    # so purge whatever might have been there
    tmp_path = stream_data['tmp_path']
    url = stream_data['url']
    stream = stream_data['stream']

    try:
        shutil.rmtree(tmp_path)
    except Exception as e:
        print e

    os.mkdir(tmp_path)

    sc_client = soundcloud.Client(client_id=client_id)

    pprint.pprint(stream)

    url = stream_data['url']

    result = sc_client.get('/resolve',
            url=url
            )

    ids = []

    if len(result.tracks):
        for track in result.tracks:
            if track['downloadable']\
                and track['original_format'] == 'flac':
                    ids.append(track['id'])
    else:
        print('hyahaa')
        sys.exit('Could not download stream files: ' + stream_data['url'])

    random.shuffle(ids)

    for id in ids:
        strid = str(id)
        path_id = tmp_path + '/' + strid

        fileflac = path_id + '.flac'
        filewav = path_id + '.wav'

        with open(fileflac, 'wb') as handle:
            response = requests.get(
                'https://api.soundcloud.com/tracks/' + strid +\
                '/download?client_id=' + client_id
                )

            for block in response.iter_content(1024):
                handle.write(block)

            handle.close()

        print("Got file " + fileflac)
        track = AudioSegment.from_file(fileflac, 'flac')
        track.export(filewav, format="wav")
        print("Written " + filewav + ", notifying")

        osc_client.connect(('127.0.0.1', 3141))
        oscmsg = OSC.OSCMessage()
        oscmsg.setAddress('/notifyfile')
        oscmsg.append('1')
        oscmsg.append(filewav)
        osc_client.send(oscmsg)


if __name__ == '__main__':
    pool = Pool(processes=len(streams))
    pool.map(download_stream_files, streams)


print("ALL DONE IN SOUNDCLOUD LAND")
