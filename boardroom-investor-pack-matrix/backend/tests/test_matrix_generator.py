import pytest
from app.services.matrix_generator import generate_matrix

def test_generate_matrix():
    # Test case for generating a basic matrix
    input_data = {
        "rows": 3,
        "columns": 3,
        "data": [
            ["A1", "B1", "C1"],
            ["A2", "B2", "C2"],
            ["A3", "B3", "C3"]
        ]
    }
    expected_output = [
        ["A1", "B1", "C1"],
        ["A2", "B2", "C2"],
        ["A3", "B3", "C3"]
    ]
    result = generate_matrix(input_data)
    assert result == expected_output

def test_generate_matrix_empty():
    # Test case for generating an empty matrix
    input_data = {
        "rows": 0,
        "columns": 0,
        "data": []
    }
    expected_output = []
    result = generate_matrix(input_data)
    assert result == expected_output

def test_generate_matrix_invalid_input():
    # Test case for handling invalid input
    input_data = {
        "rows": -1,
        "columns": 3,
        "data": []
    }
    with pytest.raises(ValueError):
        generate_matrix(input_data)