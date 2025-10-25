from fastapi import APIRouter, Depends

from src.retrieval_service.domain.models import RetrieveRequest, RetrieveResponse
from src.retrieval_service.domain.service import RetrievalService

router = APIRouter()


def get_retrieval_service() -> RetrievalService:
    """Dependency injection for retrieval service."""
    return RetrievalService()


@router.post("/retrieve", response_model=RetrieveResponse)
async def retrieve_endpoint(
    request: RetrieveRequest,
    retrieval_service: RetrievalService = Depends(get_retrieval_service),
) -> RetrieveResponse:
    """Retrieve documents based on query."""
    return await retrieval_service.retrieve_documents(request)
