"""Health check endpoints."""

from datetime import datetime, timezone

from fastapi import APIRouter

router = APIRouter()


@router.get("/health")
async def health_check():
    """Health check endpoint for container orchestration."""
    return {
        "status": "healthy",
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "service": "devsecops-api",
    }


@router.get("/ready")
async def readiness_check():
    """Readiness probe - checks if the service is ready to accept traffic."""
    # Add dependency checks here (database, cache, etc.)
    return {
        "status": "ready",
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }
