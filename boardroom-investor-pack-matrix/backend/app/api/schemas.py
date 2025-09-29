from pydantic import BaseModel
from typing import List, Optional

class MatrixItem(BaseModel):
    id: str
    name: str
    value: float
    status: str

class MatrixResponse(BaseModel):
    items: List[MatrixItem]
    total: float

class StatusResponse(BaseModel):
    status: str
    message: Optional[str] = None

class CreateMatrixRequest(BaseModel):
    items: List[MatrixItem]