FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    && rm -rf /var/lib/apt/lists/*

# Copy project configuration
COPY pyproject.toml ./

# Install CPU-only PyTorch first (to avoid CUDA dependencies)
COPY requirements-cpu.txt ./
RUN pip install --no-cache-dir -r requirements-cpu.txt --index-url https://download.pytorch.org/whl/cpu

# Install other dependencies
RUN pip install --no-cache-dir -e ".[dev]"

# Copy source code
COPY src/ ./src/
COPY tests/ ./tests/

# Create non-root user for security
RUN useradd --create-home --shell /bin/bash app && \
    chown -R app:app /app
USER app

# Expose port (will be overridden in docker-compose)
EXPOSE 8000

# Default command (will be overridden in docker-compose)
CMD ["uvicorn", "src.orchestrator.main:app", "--host", "0.0.0.0", "--port", "8000"]
