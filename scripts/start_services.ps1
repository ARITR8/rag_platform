# RAG Platform - Start All Services Script (PowerShell)
# This script starts all services for local development

Write-Host "🚀 Starting RAG Platform Services..." -ForegroundColor Green

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

# Start Redis (if not running)
Write-Host "🔴 Starting Redis..." -ForegroundColor Yellow
$redisProcess = Get-Process -Name "redis-server" -ErrorAction SilentlyContinue
if (-not $redisProcess) {
    Write-Host "⚠️  Redis not found. Please install and start Redis manually:" -ForegroundColor Red
    Write-Host "   Download from: https://github.com/microsoftarchive/redis/releases" -ForegroundColor Red
    Write-Host "   Or use Docker: docker run -d -p 6379:6379 redis:7-alpine" -ForegroundColor Red
} else {
    Write-Host "✅ Redis already running" -ForegroundColor Green
}

# Start services in background
Write-Host "🌐 Starting services..." -ForegroundColor Yellow

# Start LLM Service
Write-Host "🧠 Starting LLM Service on port 8001..." -ForegroundColor Cyan
Start-Process -FilePath "uvicorn" -ArgumentList "src.llm_service.main:app", "--host", "0.0.0.0", "--port", "8001", "--reload" -WindowStyle Hidden

# Start Retrieval Service
Write-Host "🔍 Starting Retrieval Service on port 8002..." -ForegroundColor Cyan
Start-Process -FilePath "uvicorn" -ArgumentList "src.retrieval_service.main:app", "--host", "0.0.0.0", "--port", "8002", "--reload" -WindowStyle Hidden

# Wait a moment for services to start
Start-Sleep -Seconds 3

# Start Orchestrator Service
Write-Host "🎯 Starting Orchestrator Service on port 8000..." -ForegroundColor Cyan
Start-Process -FilePath "uvicorn" -ArgumentList "src.orchestrator.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload" -WindowStyle Hidden

Write-Host ""
Write-Host "✅ All services started successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "📊 Service URLs:" -ForegroundColor White
Write-Host "   Orchestrator:  http://localhost:8000" -ForegroundColor White
Write-Host "   LLM Service:   http://localhost:8001" -ForegroundColor White
Write-Host "   Retrieval:     http://localhost:8002" -ForegroundColor White
Write-Host "   Redis:         localhost:6379" -ForegroundColor White
Write-Host ""
Write-Host "📚 API Documentation:" -ForegroundColor White
Write-Host "   Orchestrator:  http://localhost:8000/docs" -ForegroundColor White
Write-Host "   LLM Service:   http://localhost:8001/docs" -ForegroundColor White
Write-Host "   Retrieval:     http://localhost:8002/docs" -ForegroundColor White
Write-Host ""
Write-Host "🛑 To stop services, close this window or use Task Manager" -ForegroundColor Yellow
