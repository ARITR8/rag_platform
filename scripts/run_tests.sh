#!/bin/bash

# RAG Platform - Test Runner Script
# This script runs all tests with coverage reporting

set -e

echo "🧪 Running RAG Platform Tests..."

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "📦 Creating virtual environment..."
    python -m venv venv
fi

# Activate virtual environment
echo "🔧 Activating virtual environment..."
source venv/bin/activate

# Install dependencies
echo "📥 Installing dependencies..."
pip install -e ".[dev]"

# Run linting
echo "🔍 Running code quality checks..."
echo "  - Black formatting check..."
black --check src/ tests/
echo "  - isort import sorting check..."
isort --check-only src/ tests/
echo "  - flake8 linting..."
flake8 src/ tests/
echo "  - mypy type checking..."
mypy src/

# Run tests
echo "🧪 Running unit tests..."
pytest tests/unit/ -v --cov=src --cov-report=term-missing --cov-report=html

echo "🔗 Running integration tests..."
pytest tests/integration/ -v

echo ""
echo "✅ All tests completed successfully!"
echo "📊 Coverage report generated in htmlcov/index.html"
echo ""

# Check if coverage meets threshold
COVERAGE=$(pytest --cov=src --cov-report=term-missing --quiet | grep "TOTAL" | awk '{print $4}' | sed 's/%//')
if (( $(echo "$COVERAGE < 80" | bc -l) )); then
    echo "⚠️  Warning: Test coverage ($COVERAGE%) is below 80% threshold"
    exit 1
else
    echo "✅ Test coverage ($COVERAGE%) meets 80% threshold"
fi
