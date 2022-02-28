import asyncio
from asyncore import loop
from tkinter import LAST
from typing import List
from venv import create
from azure.eventhub.aio import EventHubConsumerClient
from azure.eventhub.extensions.checkpointstoreblobaio import BlobCheckpointStore
from numpy import partition

connection_str = ''
eventhub_name = 'training'
consumer_group = '$Default'
blob_container = 'checkpoint'

checkpoint_str = ''


async def EventReceiver():
    checkpoint_store = BlobCheckpointStore.from_connection_string(checkpoint_str, blob_container)
    client = EventHubConsumerClient.from_connection_string(connection_str,consumer_group=consumer_group,eventhub_name=eventhub_name,checkpoint_store=checkpoint_store)
    async with client:
        await client.receive_batch(on_event_batch=oneventbatch,max_batch_size=5,partition_id='2',starting_position='-1')
    # async with client:
    #     await client.receive(on_event=on_event,starting_position='-1',partition_id='2')

async def oneventbatch(partition_context,eventbatch):
    print (partition_context.partition_id)
    for event in eventbatch:
        print (event.properties)
    print( "New batch")
    await partition_context.update_checkpoint(eventbatch[-1])

# async def on_event(partition_context,event):
#     print (event.properties)
#     await partition_context.update_checkpoint(event)

loop = asyncio.get_event_loop()
loop.run_until_complete(EventReceiver())

