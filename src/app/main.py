from typing import Any, Dict

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from src.llm_service.api.v1.endpoints import generate
from src.orchestrator.api.v1.endpoints import query
from src.retrieval_service.api.v1.endpoints import retrieve

app = FastAPI(
    title="RAG Platform",
    description="Enterprise RAG Platform - Phase 1 MVP",
    version="0.1.0",
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure appropriately for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include the LLM service router
app.include_router(generate.router, prefix="/v1", tags=["llm"])
# Include the Retrieval service router
app.include_router(retrieve.router, prefix="/v1", tags=["retrieval"])
# Include the Orchestrator service router
app.include_router(query.router, prefix="/v1", tags=["orchestrator"])


@app.get("/health")
async def health_check() -> Dict[str, str]:
    """Health check endpoint."""
    return {"status": "healthy", "service": "rag-platform", "version": "0.1.0"}


@app.get("/")
async def root() -> Dict[str, Any]:
    """Root endpoint."""
    return {
        "message": "RAG Platform - Enterprise RAG Platform - Phase 1 MVP",
        "version": "0.1.0",
        "endpoints": {
            "health": "/health",
            "docs": "/docs",
            "llm": "/v1/generate",
            "retrieval": "/v1/retrieve",
            "orchestrator": "/v1/query",
        },
    }
