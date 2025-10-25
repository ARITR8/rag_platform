from fastapi.testclient import TestClient

from src.app.main import app

# Create the instance of the TestClient with the real app
client = TestClient(app)


def test_query_endpoint_exists() -> None:
    """Test that the /v1/query endpoint exists and returns basic response.
       Purpose:
    - Validates the basic API contract for the Orchestrator service
    - Ensures the endpoint is properly registered with FastAPI
    - Verifies the service can handle HTTP POST requests
    - This is the foundation test for the main RAG pipeline

    Business Value:
    - This is the primary endpoint that users will interact with
    - It orchestrates the entire RAG pipeline (retrieval + generation)
    - Critical for the end-to-end functionality of the platform
    - This test ensures the main API contract is working

    """

    # Test request data
    request_data = {"query": "What is the refund policy?"}

    # Make the request
    response = client.post("/v1/query", json=request_data)

    # Assert the response
    assert response.status_code == 200, "Endpoint should return 200 OK"

    # Verify basic response structure
    response_data = response.json()
    assert "answer" in response_data, "Response should contain 'answer' field"
    assert isinstance(response_data["answer"], str), "Answer should be a string"
    assert len(response_data["answer"]) > 0, "Answer should not be empty"
