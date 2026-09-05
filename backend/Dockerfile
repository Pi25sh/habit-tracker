FROM python:3.11-slim

WORKDIR /usr/src/app

# Install system dependencies for postgres and building extensions
RUN apt-get update && apt-get install -y \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Ensure app directory is in PYTHONPATH
ENV PYTHONPATH=/usr/src/app

EXPOSE 8000

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
