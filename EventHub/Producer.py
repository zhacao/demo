from azure.eventhub import EventHubProducerClient, EventData

connection_str = ''
eventhub_name = 'training'

client = EventHubProducerClient.from_connection_string(connection_str, eventhub_name=eventhub_name)

def SendEvent():
    with client:
        data = client.create_batch(partition_key='ffff')
        for num in range(30,50):
            event = EventData(f'The {num} message')
            event.properties= {"Type": "iPhone"}
            data.add(event)
        client.send_batch(data)
        
SendEvent()

