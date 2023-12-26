import os


from azure.core.exceptions import AzureError
from azure.cosmos import CosmosClient, PartitionKey


CONN_STR = os.environ["COSMOS_CONNECTION_STRING"]
client = CosmosClient.from_connection_string(CONN_STR)

database_ID="my-database"

database=client.get_database_client(database_ID)

container_id= "my-container"
container=database.get_container_client(container_id)

item_id_to_read = "Azure"

item= container.read_item(item_id_to_read,item_id_to_read)

original_count=item["count"]

new_count=original_count+1

item["count"] = new_count

container.replace_item(item=item, body=item)

item= container.read_item(item_id_to_read,item_id_to_read)

updated_count=item["count"]

if updated_count > original_count:
    print("PASS")
else:
    print("FAIL")