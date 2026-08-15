import logging, string, random, kopf
from googleapiclient.discovery import build
from google.oauth2 import service_account
from googleapiclient import http 

#Configuration
PROJECT_ID = 'kubernetes-security-505302'
REGION = 'us-central1'
SERVICE_ACCOUNT_FILE = 'C:\\Users\\hansj\\Downloads\\kubernetes-security.json'