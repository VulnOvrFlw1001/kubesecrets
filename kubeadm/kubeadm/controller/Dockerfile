FROM python:3.11-slim

WORKDIR /app

COPY controller.py .

RUN pip install kopf \
                google-auth \
                google-api-python-client


CMD [ "kopf", "run", "-v", "--log-format", "json", "controller.py" ]