FROM python:3.12-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    && rm -rf /var/lib/apt/lists/*

# Copy project configuration and source code first
COPY setup.py ./
COPY requirements-cpu.txt ./
COPY src/ ./src/
COPY tests/ ./tests/

# Install CPU-only PyTorch first (to avoid CUDA dependencies)
RUN pip install --no-cache-dir -r requirements-cpu.txt --index-url https://download.pytorch.org/whl/cpu

# Install other dependencies (excluding PyTorch which is already installed)
RUN pip install --no-cache-dir -e ".[dev]"

# Create non-root user for security
RUN useradd --create-home --shell /bin/bash app && \
    chown -R app:app /app
USER app

# Expose port (will be overridden in docker-compose)
EXPOSE 8000

# Default command (will be overridden in docker-compose)
CMD ["uvicorn", "src.app.main:app", "--host", "0.0.0.0", "--port", "8000"]
