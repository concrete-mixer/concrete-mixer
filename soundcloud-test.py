import sys
import random

import requests
import pprint
import soundcloud
from pydub import AudioSegment
from pythonosc import udp_client, osc_message, osc_message_builder
import OSC



osc_client = OSC.OSCClient()

client_id = '11bab725274cff587d5908c18cd501c2'

sc_client = soundcloud.Client(client_id=client_id)

result = sc_client.get('/resolve',
        url='https://soundcloud.com/concrete-mixer/sets/concrete-mixer-alt-files'
        )

ids = []

for track in result.tracks:
    if track['downloadable']\
        and track['original_format'] == 'flac':
            ids.append(track['id'])

random.shuffle(ids)

for id in ids:
    strid = str(id)
    fileflac = 'files/' + strid + '.flac'
    filewav = 'files/' + strid + '.wav'

    with open(fileflac, 'wb') as handle:
        response = requests.get('https://api.soundcloud.com/tracks/' + strid +\
                '/download?client_id=' + client_id)

        for block in response.iter_content(1024):
            handle.write(block)

        handle.close()

    print("Got file " + fileflac)
    track = AudioSegment.from_file(fileflac, 'flac')
    track.export('files/' + strid + '.wav', format="wav")
    print("Written " + filewav + ", notifying")

    osc_client.connect(('127.0.0.1', 3141))
    oscmsg = OSC.OSCMessage()
    oscmsg.setAddress('/notifyfile')
    oscmsg.append('1')
    oscmsg.append(filewav)
    osc_client.send(oscmsg)


print("ALL DONE IN SOUNDCLOUD LAND")
