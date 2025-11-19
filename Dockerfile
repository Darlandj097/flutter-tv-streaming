FROM python:3.11-slim

WORKDIR /app

# Instalar dependências do sistema
RUN apt-get update && apt-get install -y \
    gcc \
    python3-dev \
    libffi-dev \
    && rm -rf /var/lib/apt/lists/*

# Copiar requirements primeiro para aproveitar cache do Docker
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copiar código da aplicação
COPY tv_multimidia/ ./tv_multimidia/
COPY api_server.py .

# Configurar variáveis de ambiente
ENV PYTHONUNBUFFERED=1
ENV PYTHONIOENCODING=utf-8

EXPOSE 5000

CMD ["python", "api_server.py"]