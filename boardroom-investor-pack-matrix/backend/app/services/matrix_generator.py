from typing import List, Dict
import pandas as pd
import uuid

class MatrixGenerator:
    def __init__(self):
        self.matrix_data = []

    def generate_matrix(self, rows: int, columns: int) -> List[Dict[str, str]]:
        self.matrix_data = []
        for i in range(rows):
            row_data = {f"Column {j+1}": f"Data {i+1}-{j+1}" for j in range(columns)}
            row_data["ID"] = str(uuid.uuid4())
            self.matrix_data.append(row_data)
        return self.matrix_data

    def save_to_csv(self, file_path: str) -> None:
        df = pd.DataFrame(self.matrix_data)
        df.to_csv(file_path, index=False)

    def get_matrix(self) -> List[Dict[str, str]]:
        return self.matrix_data

    def clear_matrix(self) -> None:
        self.matrix_data = []