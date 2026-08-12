#!/bin/bash

apt-get update
apt-get install -y python3
apt-get install -y python3-pip
pip install flask psycopg2-binary