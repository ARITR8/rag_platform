from fastapi.testclient import TestClient

from src.app.main import app

# need to add end points to my test app
# @app.post("/v1/generate")
# async def generate_endpoint(request_data: dict):
#   # This is the dummy implementation for the testing
#   return {"response": "test response"}

# create the instance of the TestClient
client = TestClient(app)


def test_generate_endpoint_exists() -> None:
    """Test that the /v1/generate endpoint existis and acceps POST requests.
     Purpose:
    - Validates the basic API contract for the LLM service
    - Ensures the endpoint is properly registered with FastAPI
    - Verifies the service can handle HTTP POST requests
    - This is the foundation test for all other LLM service functionality

    Business Value:
    - Without this endpoint, the RAG pipeline cannot generate answers
    - This test ensures the service is properly configured and accessible
    - Critical for service-to-service communication in the microservices architecture

    """

    # dummy request data
    request_data = {
        "query": "test question",
        "context": [{"doc_id": "123", "content": "test context"}],
    }

    # dummy response data
    response = client.post("/v1/generate", json=request_data)

    # Now will assert the respnse whether getting expected response or not
    assert response.status_code == 200, "Endpoint should return 200 OK"

    # response strucutre verification
    response_data = response.json()
    assert "response" in response_data, "Response should contain 'response' key"
    assert isinstance(response_data["response"], str), "Response should be a string"

    # Verify the conent fo the response.
    assert (
        "test question" in response_data["response"]
    ), "Response should contain the test question"
