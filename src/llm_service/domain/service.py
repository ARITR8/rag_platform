from .models import GenerateRequest, GenerateResponse


class LLMService:
    """Service layer for LLM operations."""

    async def generate_response(self, request: GenerateRequest) -> GenerateResponse:
        """Generate a response using the LLM."""
        # TODO: Integrate with actual LLM later
        response_text = f"Generated response for query: '{request.query}' with {len(request.context)} context items"
        return GenerateResponse(response=response_text)
