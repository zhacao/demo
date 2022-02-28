import os
import string
import json
import uuid
import avro.schema

from azure.storage.blob import ContainerClient, BlobClient
from avro.datafile import DataFileReader, DataFileWriter
from avro.io import DatumReader, DatumWriter


def processBlob2(filename):
    reader = DataFileReader(open(filename, 'rb'), DatumReader())
    dict = {}
    for reading in reader:
        parsed_json = json.loads(reading["Body"])
        if not 'id' in parsed_json:
            return
        if not parsed_json['id'] in dict:
            list = []
            dict[parsed_json['id']] = list
        else:
            list = dict[parsed_json['id']]
            list.append(parsed_json)
    reader.close()
    for device in dict.keys():
        filename = os.getcwd() + '\\' + str(device) + '.csv'
        deviceFile = open(filename, "a")
        for r in dict[device]:
            deviceFile.write(", ".join([str(r[x]) for x in r.keys()])+'\n')

def startProcessing():
    print('Processor started using path: ' + os.getcwd())
    # Create a blob container client.
    container = ContainerClient.from_connection_string("AZURE STORAGE CONNECTION STRING", container_name="BLOB CONTAINER NAME")
    blob_list = container.list_blobs() # List all the blobs in the container.
    for blob in blob_list:
        # Content_length == 508 is an empty file, so process only content_length > 508 (skip empty files).        
        if blob.size > 508:
            print('Downloaded a non empty blob: ' + blob.name)
            # Create a blob client for the blob.
            blob_client = ContainerClient.get_blob_client(container, blob=blob.name)
            # Construct a file name based on the blob name.
            cleanName = str.replace(blob.name, '/', '_')
            cleanName = os.getcwd() + '\\' + cleanName 
            with open(cleanName, "wb+") as my_file: # Open the file to write. Create it if it doesn't exist. 
                my_file.write(blob_client.download_blob().readall()) # Write blob contents into the file.
            processBlob2(cleanName) # Convert the file into a CSV file.
            os.remove(cleanName) # Remove the original downloaded file.
            # Delete the blob from the container after it's read.
            container.delete_blob(blob.name)

startProcessing()