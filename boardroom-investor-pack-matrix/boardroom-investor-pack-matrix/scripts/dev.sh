#!/bin/bash

# Navigate to the backend directory and start the FastAPI server
cd backend
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload &

# Navigate to the frontend directory and start the Vite development server
cd ../frontend
npm install
npm run dev &

# Wait for both servers to start
wait