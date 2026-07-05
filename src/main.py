"""
DevSecOps Sample Application

A simple FastAPI application demonstrating security best practices
in application code.
"""

import logging
import os
from contextlib import asynccontextmanager

from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware

from src.routes import health, items
from src.middleware.security import SecurityHeadersMiddleware

# Configure structured logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan handler."""
    logger.info("Application starting up...")
    yield
    logger.info("Application shutting down...")


# Create FastAPI application
app = FastAPI(
    title="DevSecOps API",
    description="A secure API demonstrating DevSecOps best practices",
    version="1.0.0",
    docs_url="/docs" if os.getenv("ENVIRONMENT") != "production" else None,
    redoc_url="/redoc" if os.getenv("ENVIRONMENT") != "production" else None,
    lifespan=lifespan,
)

# Security Middleware
app.add_middleware(SecurityHeadersMiddleware)

# CORS - restrict origins in production
allowed_origins = os.getenv("ALLOWED_ORIGINS", "http://localhost:3000").split(",")
app.add_middleware(
    CORSMiddleware,
    allow_origins=allowed_origins,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE"],
    allow_headers=["*"],
)

# Trusted Host middleware - prevent host header attacks
allowed_hosts = os.getenv("ALLOWED_HOSTS", "localhost,127.0.0.1").split(",")
app.add_middleware(TrustedHostMiddleware, allowed_hosts=allowed_hosts)

# Register routes
app.include_router(health.router, tags=["Health"])
app.include_router(items.router, prefix="/api/v1", tags=["Items"])


@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    """Global exception handler - never expose internal details."""
    logger.error(f"Unhandled exception: {type(exc).__name__}: {exc}")
    raise HTTPException(
        status_code=500,
        detail="An internal error occurred. Please try again later.",
    )


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        "src.main:app",
        host="0.0.0.0",
        port=8000,
        reload=os.getenv("ENVIRONMENT") != "production",
        log_level="info",
    )
