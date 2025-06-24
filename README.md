# DataVista Pro

DataVista Pro is a data engineering project that processes retail sales data through a pipeline involving ingestion, storage, streaming, batch processing, and visualization. It features a web UI for uploading CSV files and viewing interactive Grafana dashboards.

## Project Overview

- **Purpose**: Ingest, process, and visualize retail sales data using modern data engineering tools.
- **Components**:
  - **Ingestion**: SQLite, MongoDB, MinIO.
  - **Streaming**: Redpanda.
  - **Batch Processing**: Dask, Dagster.
  - **Prediction**: Scikit-learn for sales predictions.
  - **Visualization**: Grafana dashboards with interactive filtering.
  - **UI**: FastAPI-based web interface for CSV uploads and dashboard display.
- **Technologies**: Python, FastAPI, Docker, MongoDB, Redpanda, MinIO, Grafana, SQLite.

## Prerequisites

- **OS**: Windows 10
- **Tools**:
  - Python 3.13 (virtualenv: `datavista`)
  - Docker Desktop
  - MongoDB 8.0 (`C:\Program Files\MongoDB\Server\8.0`)
  - VS Code with PowerShell
- **Dependencies**: Listed in `requirements.txt`
- **CSV File**: `data/input/retail_sales_dataset.csv` with columns: `Transaction ID`, `Date`, `Customer ID`, `Gender`, `Age`, `Product Category`, `Quantity`, `Price per Unit`, `Total Amount`.

## Directory Structure

```
datavista/
├── src/                    # Source code
│   ├── pipeline/           # Pipeline scripts
│   │   ├── ingest_sqlite.py
│   │   ├── ingest_mongodb.py
│   │   ├── ingest_minio.py
│   │   ├── stream_redpanda.py
│   │   ├── batch_process.py
│   │   ├── predict_sales.py
│   │   ├── export_report.py
│   │   ├── etl_pipeline.py
│   ├── web/                # Web application
│   │   ├── app.py
│   │   ├── static/
│   │   │   ├── index.html
├── config/                 # Configuration
│   ├── grafana.ini
├── data/                   # Data files
│   ├── input/              # Input CSVs
│   │   ├── retail_sales_dataset.csv
│   │   ├── uploaded_sales.csv
│   ├── output/             # Output reports
│   │   ├── sales_predictions_report.csv
│   ├── database/           # Databases
│   │   ├── data.db
├── mongodb-data/           # MongoDB data
├── README.md               # Documentation
├── Dockerfile
├── requirements.txt
```

## Setup Instructions

1. **Clone Repository** (if using GitHub):
   ```powershell
   git clone <your-repo-url>
   cd datavista
   ```

2. **Set Up Virtual Environment**:
   ```powershell
   python -m venv datavista
   .\datavista\Scripts\Activate.ps1
   pip install -r requirements.txt
   ```

3. **Start MongoDB**:
   ```powershell
   mongod --dbpath C:\datavista\mongodb-data
   ```

4. **Start Docker Services**:
   - **Redpanda**:
     ```powershell
     docker run -d --name=redpanda -p 9092:9092 -p 9644:9644 redpandadata/redpanda:latest
     ```
   - **MinIO**:
     ```powershell
     docker run -d --name=minio -p 9000:9000 -p 9001:9001 minio/minio server /data --console-address ":9001"
     ```
   - **Grafana**:
     ```powershell
     docker run -d --name=grafana -p 3001:3000 -v grafana-data:/var/lib/grafana -e "GF_INSTALL_PLUGINS=frser-sqlite-datasource" grafana/grafana
     ```

5. **Configure Grafana**:
   - Enable anonymous access and iframe embedding:
     ```powershell
     echo "[auth.anonymous]
     enabled = true
     org_role = Viewer

     [security]
     allow_embedding = true" > config\grafana.ini
     docker cp config\grafana.ini grafana:/etc/grafana/grafana.ini
     docker restart grafana
     ```
   - Copy SQLite database:
     ```powershell
     docker cp data\database\data.db grafana:/var/lib/grafana/data.db
     ```
   - In Grafana (`http://localhost:3001`):
     - Add SQLite data source:
       - Name: `datavista-sqlite`
       - Database File: `/var/lib/grafana/data.db`
     - Create “Retail Sales Dashboard” with:
       - **Bar Chart**: Sales by product category.
       - **Time Series**: Actual vs predicted sales.
       - **Table**: Sales summary.
       - **Variable**: `product_category` (`SELECT DISTINCT product_category FROM sales`).
     - Dashboard URL: `http://localhost:3001/d/3507418b-ba47-430b-8b8a-e838c667973c/retail-sales-dashboard?orgId=1&from=now-6h&to=now&timezone=browser&var-product_category=$__all`

6. **Run FastAPI**:
   ```powershell
   uvicorn src.web.app:app --host 0.0.0.0 --port 8000
   ```

7. **Run Dagster (optional)**:
   ```powershell
   dagit -h 0.0.0.0 -p 3000 -f src\pipeline\etl_pipeline.py
   ```

## UI Feature

- **Purpose**: Upload a retail sales CSV, process it, and view Grafana visualizations.
- **Access**: `http://localhost:8000`
- **Usage**:
  1. Upload a CSV (`data/input/retail_sales_dataset.csv`) with required columns.
  2. Click "Upload & Process".
  3. View the dashboard in an iframe.
  4. Filter using the `Product Category` dropdown.
  5. Download the report from MinIO (`http://localhost:9000/datavista-bucket/sales_predictions_report.csv`).
- **Dashboard URL**: `http://localhost:3001/d/3507418b-ba47-430b-8b8a-e838c667973c/retail-sales-dashboard?orgId=1&from=now-6h&to=now&timezone=browser&var-product_category=$__all`
- **Requirements**: FastAPI, MongoDB, Redpanda, Grafana (port 3001 with `frser-sqlite-datasource`), MinIO, Docker.
- **Note**: Only CSVs matching the specified schema are supported. Ensure Grafana has `allow_embedding = true`.

## Pipeline Details

1. **Ingestion**:
   - `src/pipeline/ingest_sqlite.py`: Loads CSV to SQLite (`sales` table).
   - `src/pipeline/ingest_mongodb.py`: Stores data in MongoDB.
   - `src/pipeline/ingest_minio.py`: Uploads CSV to MinIO (`datavista-bucket`).
2. **Streaming**:
   - `src/pipeline/stream_redpanda.py`: Streams data via Redpanda.
3. **Batch Processing**:
   - `src/pipeline/batch_process.py`: Aggregates data to `sales_summary`.
   - `src/pipeline/etl_pipeline.py`: Orchestrates pipeline with Dagster.
4. **Prediction**:
   - `src/pipeline/predict_sales.py`: Generates `sales_predictions`.
5. **Export**:
   - `src/pipeline/export_report.py`: Saves predictions to `data/output/sales_predictions_report.csv`.
6. **Visualization**:
   - Grafana dashboard with `product_category` filtering.

## Troubleshooting

- **UI Error: "localhost refused to connect"**:
  - Verify `grafana_url` in `src/web/app.py`.
  - Ensure `config/grafana.ini` has `allow_embedding = true`.
  - Check browser console (F12 → Console).
  - Confirm Grafana: `docker ps -a`.
- **SQLite Errors**:
  - Verify `data/database/data.db`:
    ```powershell
    sqlite3 data\database\data.db
    .tables
    PRAGMA table_info(sales_predictions);
    ```
  - Re-run scripts:
    ```powershell
    $env:CSV_PATH="C:\datavista\data\input\uploaded_sales.csv"
    python src\pipeline\ingest_sqlite.py
    python src\pipeline\batch_process.py
    python src\pipeline\predict_sales.py
    ```
- **Grafana Issues**:
  - Check logs: `docker logs grafana`.
  - Reinstall plugin: `docker exec grafana grafana cli plugins install frser-sqlite-datasource`.

## Future Improvements

- Support dynamic CSV schemas.
- Add more visualizations (e.g., pie charts).
- Enhance UI with time range controls.

## License

MIT License. See `LICENSE` for details.