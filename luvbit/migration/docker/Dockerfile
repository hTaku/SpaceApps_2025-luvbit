FROM python:3.11-slim

WORKDIR /migration

COPY migration/requirements.txt .
RUN pip install -r requirements.txt

COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]