from pydantic import BaseSettings

class Settings(BaseSettings):
    app_name: str = "Boardroom Investor Pack Matrix"
    api_version: str = "v1"
    debug: bool = False
    database_url: str
    secret_key: str
    allowed_hosts: list[str] = []

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"

settings = Settings()