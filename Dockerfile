FROM python:3.13-slim

WORKDIR /app
COPY src/ src/
COPY requirements.txt .

RUN pip install --no-cache-dir \
    pandas \
    dask[complete] \
    dagster \
    dagit \
    scikit-learn \
    pymongo \
    minio \
    kafka-python \
    fastapi \
    uvicorn

EXPOSE 3000 8000

CMD ["sh", "-c", "uvicorn src.web.app:app --host 0.0.0.0 --port 8000 & dagit -h 0.0.0.0 -p 3000 -f src/pipeline/etl_pipeline.py"]