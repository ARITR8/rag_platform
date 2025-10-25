from .models import Document, RetrieveRequest, RetrieveResponse


class RetrievalService:
    """Service layer for document retrieval operations."""

    async def retrieve_documents(self, request: RetrieveRequest) -> RetrieveResponse:
        """Retrieve documents based on query."""
        # Mock implementation - returns fake documents
        mock_documents = [
            Document(
                doc_id="mock_doc_001",
                content="This is a mock document about the query: " + request.query,
                score=0.95,
            ),
            Document(
                doc_id="mock_doc_002",
                content="Another mock document related to: " + request.query,
                score=0.87,
            ),
            Document(
                doc_id="mock_doc_003",
                content="Third mock document for: " + request.query,
                score=0.82,
            ),
        ]

        # Return only the requested number of documents
        return RetrieveResponse(documents=mock_documents[: request.limit])
