from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_read_root():
    response = client.get("/")
    assert response.status_code == 200
    assert response.json() == {"message": "Welcome to the Boardroom Investor Pack Matrix API"}

def test_get_matrix_data():
    response = client.get("/api/matrix")
    assert response.status_code == 200
    assert isinstance(response.json(), list)  # Assuming the response is a list of matrix data

def test_create_matrix():
    response = client.post("/api/matrix", json={"data": "sample data"})
    assert response.status_code == 201
    assert "id" in response.json()  # Assuming the response contains an ID for the created matrix

def test_status_polling():
    response = client.get("/api/matrix/status")
    assert response.status_code == 200
    assert "status" in response.json()  # Assuming the response contains a status field

def test_copy_to_clipboard():
    response = client.post("/api/matrix/copy", json={"data": "sample data"})
    assert response.status_code == 200
    assert response.json() == {"message": "Data copied to clipboard"}  # Assuming this is the expected response