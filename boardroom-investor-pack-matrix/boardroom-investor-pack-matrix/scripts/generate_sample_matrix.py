import random
import json

def generate_sample_matrix(num_rows=5, num_columns=3):
    matrix = []
    for _ in range(num_rows):
        row = [random.randint(1, 100) for _ in range(num_columns)]
        matrix.append(row)
    return matrix

def save_matrix_to_file(matrix, filename='sample_matrix.json'):
    with open(filename, 'w') as f:
        json.dump(matrix, f, indent=4)

if __name__ == "__main__":
    sample_matrix = generate_sample_matrix()
    save_matrix_to_file(sample_matrix)