FROM python:3.10-slim

# Dependencias para psycopg2 y utilidades
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

# EXPOSICIÓN Y EJECUCIÓN
EXPOSE 8000

# IMPORTANTE: Cambiado de main:app a app.main:app
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]