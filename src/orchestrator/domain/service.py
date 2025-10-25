import httpx

from .models import QueryRequest, QueryResponse, Source


class OrchestratorService:
    """Service layer for orchestrating the RAG pipeline."""

    def __init__(self, test_mode: bool = False):
        self.test_mode = test_mode
        if not test_mode:
            # Use internal service calls (same server)
            self.retrieval_url = "http://localhost:8000/v1/retrieve"
            self.llm_url = "http://localhost:8000/v1/generate"

    async def process_query(self, request: QueryRequest) -> QueryResponse:
        """Process a query through the RAG pipeline."""

        if self.test_mode:
            # Mock implementation for testing
            return QueryResponse(
                answer=f"Mock answer for query: {request.query}",
                sources=[
                    Source(
                        doc_id="mock_doc_001",
                        snippet="This is a mock document snippet...",
                        score=0.95,
                    ),
                    Source(
                        doc_id="mock_doc_002",
                        snippet="Another mock document snippet...",
                        score=0.87,
                    ),
                ],
                meta={"cache_hit": False, "latency_ms": 420},
            )

        # Real implementation for production
        try:
            # Step 1: Retrieve documents
            retrieval_request = {"query": request.query, "limit": request.limit}

            async with httpx.AsyncClient() as client:
                # Call retrieval service
                retrieval_response = await client.post(
                    self.retrieval_url, json=retrieval_request, timeout=30.0
                )
                retrieval_response.raise_for_status()
                retrieval_data = retrieval_response.json()

                # Step 2: Generate answer using LLM
                llm_request = {
                    "query": request.query,
                    "context": retrieval_data["documents"],
                }

                llm_response = await client.post(
                    self.llm_url, json=llm_request, timeout=30.0
                )
                llm_response.raise_for_status()
                llm_data = llm_response.json()

            # Step 3: Format response
            sources = [
                Source(
                    doc_id=doc["doc_id"],
                    snippet=doc["content"][:100] + "...",  # Truncate for snippet
                    score=doc["score"],
                )
                for doc in retrieval_data["documents"]
            ]

            return QueryResponse(
                answer=llm_data["response"],
                sources=sources,
                meta={
                    "cache_hit": False,  # TODO: Add Redis cache
                    "latency_ms": 420,  # TODO: Add real timing
                },
            )

        except httpx.RequestError:
            # Fallback to mock response if services are not available
            return QueryResponse(
                answer=f"Service temporarily unavailable. Mock answer for: {request.query}",
                sources=[
                    Source(
                        doc_id="fallback_doc",
                        snippet="Service fallback response",
                        score=0.5,
                    )
                ],
                meta={
                    "cache_hit": False,
                    "latency_ms": 100,
                    "error": "Service unavailable, using fallback",
                },
            )
