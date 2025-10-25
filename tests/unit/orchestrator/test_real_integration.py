from fastapi.testclient import TestClient

from src.app.main import app

# Create the instance of the TestClient with the real app
client = TestClient(app)


def test_orchestrator_makes_real_http_calls() -> None:
    """Test that the orchestrator makes real HTTP calls to other services.
       Purpose:
    - Validates that orchestrator integrates with retrieval and LLM services
    - Ensures the full RAG pipeline works end-to-end
    - This test will fail until we implement real HTTP calls

    Business Value:
    - This is the core integration test for the RAG platform
    - Ensures all services work together as a complete system
    - Critical for validating the microservices architecture

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

    # Verify the answer is not a mock response
    answer = response_data["answer"]
    assert "Mock answer" not in answer, "Should not return mock answer"
    assert "test_mode" not in answer, "Should not be in test mode"

    # Verify sources are real (not mock)
    sources = response_data["sources"]
    assert len(sources) > 0, "Should have sources"
    assert sources[0]["doc_id"] != "mock_doc_001", "Should not use mock doc IDs"
