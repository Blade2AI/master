# End-to-End Integration Tests Documentation

## Overview

This document outlines the end-to-end integration tests for the Boardroom Investor Pack Matrix application. The purpose of these tests is to ensure that the entire application stack, from the frontend to the backend, functions as expected when integrated together.

## Test Scenarios

1. **User Authentication**
   - Verify that users can log in and log out successfully.
   - Ensure that session management works correctly.

2. **Matrix Generation**
   - Test the process of generating a new investor pack matrix.
   - Validate that the generated matrix meets the expected format and data integrity.

3. **Status Polling**
   - Confirm that the frontend can poll the backend for the status of matrix generation.
   - Ensure that the status updates are reflected in the UI in real-time.

4. **Dashboard Functionality**
   - Verify that the dashboard displays the correct data from the generated matrix.
   - Ensure that all components of the dashboard are functional and responsive.

5. **Copy-to-Clipboard Functionality**
   - Test the clipboard functionality to ensure that users can copy matrix data easily.
   - Validate that the copied data matches the displayed matrix data.

## Setup Instructions

1. **Prerequisites**
   - Ensure that Docker and Docker Compose are installed on your machine.
   - Clone the repository and navigate to the project directory.

2. **Running the Application**
   - Use the following command to start the application:
     ```
     docker-compose up --build
     ```

3. **Accessing the Application**
   - Open your web browser and navigate to `http://localhost:3000` to access the frontend.

## Running Tests

- To execute the end-to-end tests, use the following command:
  ```
  npm run test:e2e
  ```

## Reporting Issues

If you encounter any issues during testing, please report them in the project's issue tracker with detailed information about the problem and steps to reproduce it.