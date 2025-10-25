from fastapi import APIRouter, Depends

from src.llm_service.domain.models import GenerateRequest, GenerateResponse
from src.llm_service.domain.service import LLMService

router = APIRouter()


def get_llm_service() -> LLMService:
    """Dependency injection for LLM service."""
    return LLMService()


@router.post("/generate", response_model=GenerateResponse)
async def generate_endpoint(
    request: GenerateRequest, llm_service: LLMService = Depends(get_llm_service)
) -> GenerateResponse:
    """Generate a response using the LLM service."""
    return await llm_service.generate_response(request)
