import random
import re
import sys
import os
import shutil
from multiprocessing import Pool

import requests
import soundcloud
from pydub import AudioSegment
import OSC


streams = []


filename = 'concrete.conf'
lines = open(filename, 'r').read().split('\n')

for line in lines:
    matches = re.match(r'^stream(\d+)Url=(.*)$', line)

    if matches:
        stream = matches.group(1)
        streams.append({
                'stream': matches.group(1),
                'url': matches.group(2),
                'tmp_path': '/tmp/concreteMixerStream' + stream
                })

if not len(streams):
    sys.exit('No streams found to download')

osc_client = OSC.OSCClient()

# this is Concrete Mixer's own app key so please use it nicely
client_id = '11bab725274cff587d5908c18cd501c2'


def download_stream_files(stream_data):
    # because of Soundcloud API's T&Cs we can't store files we download
    # so purge whatever might have been there
    tmp_path = stream_data['tmp_path']
    url = stream_data['url']

    try:
        shutil.rmtree(tmp_path)
    except Exception as e:
        print(e)

    if not os.path.isdir(tmp_path):
        os.mkdir(tmp_path)

    sc_client = soundcloud.Client(client_id=client_id)

    url = stream_data['url']

    result = sc_client.get(
        '/resolve', url=url
    )

    tracks = []

    if len(result.tracks):
        for track in result.tracks:
            if track['downloadable']:
                tracks.append({
                    'id': track['id'],
                    'ext': track['original_format'],
                    })
    else:
        sys.exit('Could not download stream files: ' + stream_data['url'])

    random.shuffle(tracks)

    if not len(tracks):
        sys.exit("NO SOUND FILES FOR STREAM {}".format(stream_data['url']))

    for track_in in tracks:
        strid = str(track_in['id'])
        ext = track_in['ext']
        path_id = tmp_path + '/' + strid + '.'

        file_in = path_id + ext
        print("Got file " + file_in)

        needs_conversion = ext not in ['aiff', 'wav']

        if needs_conversion:
            file_out = path_id + 'wav'
        else:
            file_out = file_in

        if not os.path.isfile(file_out):
            with open(file_in, 'wb') as handle:
                response = requests.get(
                    'https://api.soundcloud.com/tracks/{}'.format(strid) +
                    '/download?client_id={}'.format(client_id)
                )

                for block in response.iter_content(1024):
                    handle.write(block)

                handle.close()

            if needs_conversion:
                track_out = AudioSegment.from_file(file_in, ext)
                track_out.export(file_out, format="wav")

        print("Got " + file_out + ", notifying")

        notify_wav(file_out)


def notify_wav(file_out):
    osc_client.connect(('127.0.0.1', 2424))
    oscmsg = OSC.OSCMessage()
    oscmsg.setAddress('/notifyfile')
    oscmsg.append('1')
    oscmsg.append(file_out)
    osc_client.send(oscmsg)


if __name__ == '__main__':
    pool = Pool(processes=len(streams))
    pool.map(download_stream_files, streams)


print("SOUNDCLOUD FILES DOWNLOAD COMPLETE")
