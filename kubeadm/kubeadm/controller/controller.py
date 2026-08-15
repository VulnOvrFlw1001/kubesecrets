import logging, string, random, kopf
from googleapiclient.discovery import build
from google.oauth2 import service_account
from googleapiclient import http 

#Configuration
PROJECT_ID = 'kubernetes-security-505302'
REGION = 'us-central1'
SERVICE_ACCOUNT_FILE = 'C:\\Users\\hansj\\Downloads\\kubernetes-security.json'
NETWORK = f'projects/{PROJECT_ID}/global/networks/kubeadm-network'

#Authentication
credentials = service_account.Credentials.from_service_account_file(
    SERVICE_ACCOUNT_FILE
)

#Custom Timeout for HTTP requests
http.DEFAULT_HTTP_TIMEOUT_SEC = 300

#Client
sqladmin = build('sqladmin', 'v1beta4', credentials=credentials)

#Password generator
def generate_password():
    length = 10
    chars = string.ascii_lowercase + string.digits
    return ''.join(random.choice(chars) for _ in range(length))

#Create CLOUDSQL Instance
def create_cloudsql_instance(name, instance_tier, db_version):
    root_password = generate_password()

    body = {
        'name': name,
        'databaseVersion': db_version, 
        'region': REGION,
        'availabilityType': 'REGIONAL',
        'settings': {
            'tier': instance_tier, 
            'ipConfiguration': {
                'ipv4Enabled': False,
                'privateNetwork': NETWORK,
                'enablePrivatePathForGoogleCloudSeervices': True
            }
        },
        'rootPassword': root_password
    }
    try:
        response = sqladmin.instances().insert(project=PROJECT_ID,body=body).execute()
        logging.info(f"Instance creation started: {response.get('name')}")
    except Exception as e:
        logging.error(f"Failed to create instance: {e}")

#Delete CLOUDSQL Instance
def delete_cloudsql_instance(name):
    try:
        response = sqladmin.instances().delete(project=PROJECT_ID, instance=name).execute()
        logging.info(f"Instance deletion started: {response.get('name')}")
    except Exception as e:
        logging.error(f"Failed to delete instance: {e}")

#create_cloudsql_instance("my-test-cloudsql-instance", "db-fi-micro", "POSTGRES_15")
#delete_cloudsql_instance("my-test-cloudsql-instance")

#KOPF Create handler

@kopf.on.create("sql.gcp", "v1", "cloudsqlinstance")
def create_instance(spec, name, **kwargs):
    logging.info(f"Received creation request for Cloud SQL instance: {name}")

    db_version = spec.get("dbVersion")
    instance_tier = spec.get("instanceTier")
    instance_name = spec.get("name")

    create_cloudsql_instance(instance_name, instance_tier, db_version)

# KOPF Delete handler
@kopf.on.delete("sql.gcp", "v1", "cloudsqlinstance")
def delete_instance(spec, name, **kwargs):
    logging.info(f"Deleting Cloud SQL instance: {name}")
    instance_name = spec.get("name")

    delete_cloudsql_instance(instance_name)