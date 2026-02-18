"""Pytest fixtures for API tests."""

import os

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

# Use SQLite in-memory for fast unit tests
TEST_DATABASE_URL = "sqlite:///./test.db"

os.environ.setdefault("DATABASE_URL", TEST_DATABASE_URL)
os.environ.setdefault("MEMORY_DB_PATH", "/tmp/test-chromadb")
os.environ.setdefault("LOG_JSON", "false")

from app.core.database import Base, get_db  # noqa: E402
from app.main import app  # noqa: E402

engine = create_engine(TEST_DATABASE_URL, connect_args={"check_same_thread": False})
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


@pytest.fixture(scope="session", autouse=True)
def create_tables():
    """Create all tables once per test session."""
    Base.metadata.create_all(bind=engine)
    yield
    Base.metadata.drop_all(bind=engine)


@pytest.fixture
def db():
    """Provide a transactional DB session that rolls back after each test."""
    connection = engine.connect()
    transaction = connection.begin()
    session = TestingSessionLocal(bind=connection)
    yield session
    session.close()
    transaction.rollback()
    connection.close()


@pytest.fixture
def client(db):
    """FastAPI TestClient with DB dependency overridden."""

    def override_get_db():
        yield db

    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as c:
        yield c
    app.dependency_overrides.clear()
