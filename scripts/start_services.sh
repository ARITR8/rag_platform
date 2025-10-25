#!/bin/bash

# RAG Platform - Start All Services Script
# This script starts all services for local development

set -e

echo "🚀 Starting RAG Platform Services..."

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

# Start Redis (if not running)
echo "🔴 Starting Redis..."
if ! pgrep -x "redis-server" > /dev/null; then
    redis-server --daemonize yes --port 6379
    echo "✅ Redis started on port 6379"
else
    echo "✅ Redis already running"
fi

# Start services in background
echo "🌐 Starting services..."

# Start LLM Service
echo "🧠 Starting LLM Service on port 8001..."
uvicorn src.llm_service.main:app --host 0.0.0.0 --port 8001 --reload &
LLM_PID=$!

# Start Retrieval Service
echo "🔍 Starting Retrieval Service on port 8002..."
uvicorn src.retrieval_service.main:app --host 0.0.0.0 --port 8002 --reload &
RETRIEVAL_PID=$!

# Wait a moment for services to start
sleep 3

# Start Orchestrator Service
echo "🎯 Starting Orchestrator Service on port 8000..."
uvicorn src.orchestrator.main:app --host 0.0.0.0 --port 8000 --reload &
ORCHESTRATOR_PID=$!

echo ""
echo "✅ All services started successfully!"
echo ""
echo "📊 Service URLs:"
echo "   Orchestrator:  http://localhost:8000"
echo "   LLM Service:   http://localhost:8001"
echo "   Retrieval:     http://localhost:8002"
echo "   Redis:         localhost:6379"
echo ""
echo "📚 API Documentation:"
echo "   Orchestrator:  http://localhost:8000/docs"
echo "   LLM Service:   http://localhost:8001/docs"
echo "   Retrieval:     http://localhost:8002/docs"
echo ""
echo "🛑 To stop all services, press Ctrl+C"

# Function to cleanup on exit
cleanup() {
    echo ""
    echo "🛑 Stopping services..."
    kill $ORCHESTRATOR_PID 2>/dev/null || true
    kill $RETRIEVAL_PID 2>/dev/null || true
    kill $LLM_PID 2>/dev/null || true
    echo "✅ All services stopped"
    exit 0
}

# Set trap to cleanup on script exit
trap cleanup SIGINT SIGTERM

# Wait for all background processes
wait
