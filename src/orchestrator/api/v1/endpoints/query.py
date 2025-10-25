from fastapi import APIRouter, Depends

from src.orchestrator.domain.models import QueryRequest, QueryResponse
from src.orchestrator.domain.service import OrchestratorService

router = APIRouter()


def get_orchestrator_service() -> OrchestratorService:
    """Dependency injection for orchestrator service."""
    # Use real integration mode (not test mode)
    return OrchestratorService(test_mode=False)


@router.post("/query", response_model=QueryResponse)
async def query_endpoint(
    request: QueryRequest,
    orchestrator_service: OrchestratorService = Depends(get_orchestrator_service),
) -> QueryResponse:
    """Process a query through the RAG pipeline."""
    return await orchestrator_service.process_query(request)
