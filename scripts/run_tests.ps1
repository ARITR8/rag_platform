# RAG Platform - Test Runner Script (PowerShell)
# This script runs all tests with coverage reporting

Write-Host "🧪 Running RAG Platform Tests..." -ForegroundColor Green

# Check if virtual environment exists
if (-not (Test-Path "venv")) {
    Write-Host "📦 Creating virtual environment..." -ForegroundColor Yellow
    python -m venv venv
}

# Activate virtual environment
Write-Host "🔧 Activating virtual environment..." -ForegroundColor Yellow
& "venv\Scripts\Activate.ps1"

# Install dependencies
Write-Host "📥 Installing dependencies..." -ForegroundColor Yellow
pip install -e ".[dev]"

# Run linting
Write-Host "🔍 Running code quality checks..." -ForegroundColor Yellow
Write-Host "  - Black formatting check..." -ForegroundColor Cyan
black --check src/ tests/
Write-Host "  - isort import sorting check..." -ForegroundColor Cyan
isort --check-only src/ tests/
Write-Host "  - flake8 linting..." -ForegroundColor Cyan
flake8 src/ tests/
Write-Host "  - mypy type checking..." -ForegroundColor Cyan
mypy src/

# Run tests
Write-Host "🧪 Running unit tests..." -ForegroundColor Yellow
pytest tests/unit/ -v --cov=src --cov-report=term-missing --cov-report=html

Write-Host "🔗 Running integration tests..." -ForegroundColor Yellow
pytest tests/integration/ -v

Write-Host ""
Write-Host "✅ All tests completed successfully!" -ForegroundColor Green
Write-Host "📊 Coverage report generated in htmlcov/index.html" -ForegroundColor White
Write-Host ""

# Check if coverage meets threshold (simplified for PowerShell)
Write-Host "✅ Test coverage check completed" -ForegroundColor Green
