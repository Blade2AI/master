# Boardroom Investor Pack Matrix Backend

This is the backend for the Boardroom Investor Pack Matrix project, which provides an API for generating and managing investor pack matrices.

## Features

- **Matrix Generation**: Generate investor pack matrices with customizable parameters.
- **Status Tracking**: Monitor the status of matrix generation processes.
- **API Endpoints**: Access various functionalities through RESTful API endpoints.

## Project Structure

```
backend/
├── app/
│   ├── __init__.py
│   ├── main.py
│   ├── api/
│   │   ├── __init__.py
│   │   ├── routes.py
│   │   └── schemas.py
│   ├── core/
│   │   ├── config.py
│   │   └── logging.py
│   ├── services/
│   │   ├── matrix_generator.py
│   │   └── status_tracker.py
│   └── utils/
│       └── id_factory.py
├── tests/
│   ├── test_api.py
│   └── test_matrix_generator.py
├── requirements.txt
└── README.md
```

## Installation

1. Clone the repository:
   ```
   git clone <repository-url>
   cd boardroom-investor-pack-matrix/backend
   ```

2. Install the required packages:
   ```
   pip install -r requirements.txt
   ```

## Running the Application

To run the backend application, execute the following command:
```
uvicorn app.main:app --reload
```

## Testing

To run the tests, use:
```
pytest tests/
```

## License

This project is licensed under the MIT License. See the LICENSE file for details.