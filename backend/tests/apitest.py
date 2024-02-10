import os
from azure.identity import DefaultAzureCredential
from azure.core.exceptions import AzureError
from azure.cosmos import CosmosClient, PartitionKey


URI = "https://tf-ray-resume-cosmosdb.documents.azure.com:443/"
KEY = "3voBEaObThaXVAv2Kv9JHc28GY6ljoy4LvXrIhCV96SwbGVQRS1yE3mtIOuoDX69k39TR73vrHZTACDbthewog=="
client = CosmosClient(URI,KEY)

database_ID="tf-resume-db"

database=client.get_database_client(database_ID)

container_id= "db-container"
container=database.get_container_client(container_id)

item_id_to_read = "Azure"

item= container.read_item(item_id_to_read,item_id_to_read)

original_count=item["Count"]

new_count=original_count+1

item["count"] = new_count

container.replace_item(item=item, body=item)

item= container.read_item(item_id_to_read,item_id_to_read)

updated_count=item["count"]

if updated_count > original_count:
    print("PASS")
else:
    print("FAIL")