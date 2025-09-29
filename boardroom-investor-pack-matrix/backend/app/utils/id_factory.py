from uuid import uuid4

def generate_unique_id() -> str:
    return str(uuid4())

def generate_batch_ids(batch_size: int) -> list:
    return [generate_unique_id() for _ in range(batch_size)]