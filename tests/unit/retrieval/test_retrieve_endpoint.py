from fastapi.testclient import TestClient

from src.app.main import app

# Create the instance of the TestClient with the real app
client = TestClient(app)


def test_retrieve_endpoint_exists() -> None:
    """Test that the /v1/retrieve endpoint exists and accepts POST requests.
       Purpose:
    - Validates the basic API contract for the Retrieval service
    - Ensures the endpoint is properly registered with FastAPI
    - Verifies the service can handle HTTP POST requests
    - This is the foundation test for all other Retrieval service functionality

    Business Value:
    - Without this endpoint, the RAG pipeline cannot retrieve relevant documents
    - This test ensures the service is properly configured and accessible
    - Critical for service-to-service communication in the microservices architecture

    """

    # Test request data
    request_data = {"query": "test question", "limit": 5}

    # Make the request
    response = client.post("/v1/retrieve", json=request_data)

    # Assert the response
    assert response.status_code == 200, "Endpoint should return 200 OK"

    # Verify response structure
    response_data = response.json()
    assert "documents" in response_data, "Response should contain 'documents' field"
    assert isinstance(response_data["documents"], list), "Documents should be a list"
    assert len(response_data["documents"]) > 0, "Should return at least one document"

    # Verify document structure
    doc = response_data["documents"][0]
    assert "doc_id" in doc, "Document should have doc_id"
    assert "content" in doc, "Document should have content"
    assert "score" in doc, "Document should have score"
