from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from typing import List

router = APIRouter()

class MatrixData(BaseModel):
    id: str
    name: str
    status: str

class MatrixResponse(BaseModel):
    data: List[MatrixData]

@router.get("/matrix", response_model=MatrixResponse)
async def get_matrix():
    # Logic to retrieve matrix data
    return {"data": []}

@router.post("/matrix", response_model=MatrixData)
async def create_matrix(matrix_data: MatrixData):
    # Logic to create a new matrix entry
    return matrix_data

@router.get("/matrix/{matrix_id}", response_model=MatrixData)
async def get_matrix_by_id(matrix_id: str):
    # Logic to retrieve a specific matrix entry by ID
    raise HTTPException(status_code=404, detail="Matrix not found")