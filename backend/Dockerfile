FROM python:3.10-slim

# Dependencias para psycopg2
RUN apt-get update && apt-get install -y \
    libpq-dev \
    gcc \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Instalar dependencias
COPY requerimientos.txt .
RUN pip install --no-cache-dir -r requerimientos.txt

# Copiar el resto del código
COPY . .

EXPOSE 8009

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8009"]