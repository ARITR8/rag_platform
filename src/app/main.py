from fastapi import FastAPI

from src.llm_service.api.v1.endpoints import generate
from src.orchestrator.api.v1.endpoints import query
from src.retrieval_service.api.v1.endpoints import retrieve

app = FastAPI(
    title="RAG Platform",
    description="Enterprise RAG Platform - Phase 1 MVP",
    version="0.1.0",
)

# Include the LLM service router
app.include_router(generate.router, prefix="/v1", tags=["llm"])
# Include the Retrieval service router
app.include_router(retrieve.router, prefix="/v1", tags=["retrieval"])

# Include the Orchestrator service router
app.include_router(query.router, prefix="/v1", tags=["orchestrator"])
