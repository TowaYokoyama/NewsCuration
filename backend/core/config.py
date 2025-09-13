from pydantic_settings import BaseSettings

class Settings(BaseSettings):
        DATABASE_URL: str = "postgresql://user:password@localhost:5432/newscuration?client_encoding=UTF8"
        RAKUTEN_APP_ID: str = "YOUR_RAKUTEN_APP_ID_HERE" # Please replace with your actual Rakuten App ID
        
        class Config:
            env_file = ".env"

settings = Settings()
