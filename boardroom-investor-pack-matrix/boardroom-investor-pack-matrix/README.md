# Boardroom Investor Pack Matrix

## Overview
The Boardroom Investor Pack Matrix project is designed to provide a comprehensive solution for generating and managing investor pack matrices. It consists of a Python backend built with FastAPI and a React/TypeScript frontend. The application includes features for status polling, a dashboard for visualizing data, and copy-to-clipboard functionality for ease of use.

## Project Structure
The project is organized into several key directories:

- **backend/**: Contains the Python backend application.
  - **app/**: The main application code, including API routes, services, and utilities.
  - **tests/**: Unit tests for the backend application.
  - **requirements.txt**: Lists the dependencies required for the backend.
  - **README.md**: Documentation specific to the backend.

- **frontend/**: Contains the React/TypeScript frontend application.
  - **src/**: The source code for the frontend, including components, hooks, context, and services.
  - **public/**: Static files for the frontend application.
  - **package.json**: Configuration for npm dependencies and scripts.
  - **tsconfig.json**: TypeScript configuration file.
  - **vite.config.ts**: Configuration for Vite, the build tool.

- **infra/**: Contains Docker configurations and Docker Compose files for deploying the application.

- **scripts/**: Utility scripts for development and testing.

- **tests/**: Documentation for integration tests.

## Features
- **Status Polling**: The application polls the backend for updates on the matrix generation process, providing real-time feedback to users.
- **Dashboard**: A user-friendly dashboard displays the investor pack matrix and relevant status information.
- **Copy-to-Clipboard**: Users can easily copy matrix data to the clipboard for sharing or further processing.

## Getting Started
To get started with the project, follow these steps:

1. Clone the repository:
   ```
   git clone <repository-url>
   cd boardroom-investor-pack-matrix
   ```

2. Set up the backend:
   - Navigate to the `backend` directory.
   - Install the required dependencies:
     ```
     pip install -r requirements.txt
     ```
   - Run the backend application:
     ```
     uvicorn app.main:app --reload
     ```

3. Set up the frontend:
   - Navigate to the `frontend` directory.
   - Install the required dependencies:
     ```
     npm install
     ```
   - Run the frontend application:
     ```
     npm run dev
     ```

4. Access the application in your web browser at `http://localhost:3000`.

## Contributing
Contributions are welcome! Please submit a pull request or open an issue for any enhancements or bug fixes.

## License
This project is licensed under the MIT License. See the LICENSE file for more details.