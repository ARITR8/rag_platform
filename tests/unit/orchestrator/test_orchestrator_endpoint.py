from fastapi.testclient import TestClient

from src.app.main import app

# Create the instance of the TestClient with the real app
client = TestClient(app)


def test_orchestrator_endpoint_works_with_mock_services() -> None:
    """Test that the orchestrator endpoint works with current mock implementations.
       Purpose:
    - Validates that orchestrator endpoint is accessible and functional
    - Ensures the API structure is correct for future real implementations
    - Tests the current mock-based RAG pipeline

    Business Value:
    - Validates the API contract and response structure
    - Ensures the orchestrator can handle requests properly
    - Foundation for future real service integration

    """

    # Test request data
    request_data = {"query": "What is the refund policy?", "limit": 2}

    # Make the request
    response = client.post("/v1/query", json=request_data)

    # Assert the response
    assert response.status_code == 200, "Endpoint should return 200 OK"

    # Verify response structure
    response_data = response.json()
    assert "answer" in response_data, "Response should contain 'answer' field"
    assert "sources" in response_data, "Response should contain 'sources' field"
    assert "meta" in response_data, "Response should contain 'meta' field"

    # Verify the response has expected structure (works with current mock implementation)
    answer = response_data["answer"]
    assert isinstance(answer, str), "Answer should be a string"
    assert len(answer) > 0, "Answer should not be empty"

    # Verify sources structure (works with current mock implementation)
    sources = response_data["sources"]
    assert isinstance(sources, list), "Sources should be a list"
    assert len(sources) > 0, "Should have sources"

    # Verify source structure
    source = sources[0]
    assert "doc_id" in source, "Source should have doc_id"
    assert "content" in source, "Source should have content"
    assert "score" in source, "Source should have score"
