"""Items API endpoints demonstrating secure coding practices."""

import logging
import uuid
from typing import Optional

from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel, Field, validator

logger = logging.getLogger(__name__)

router = APIRouter()


# --- Models with input validation ---


class ItemCreate(BaseModel):
    """Item creation model with strict validation."""

    name: str = Field(
        ...,
        min_length=1,
        max_length=200,
        description="Item name",
        examples=["Secure Widget"],
    )
    description: Optional[str] = Field(
        None,
        max_length=1000,
        description="Item description",
    )
    price: float = Field(..., gt=0, le=1_000_000, description="Item price")

    @validator("name")
    def sanitize_name(cls, v):
        """Sanitize input to prevent injection attacks."""
        # Strip potentially dangerous characters
        forbidden_chars = ["<", ">", "&", "'", '"', ";", "--"]
        for char in forbidden_chars:
            if char in v:
                raise ValueError(f"Invalid character in name: {char}")
        return v.strip()


class ItemResponse(BaseModel):
    """Item response model."""

    id: str
    name: str
    description: Optional[str]
    price: float


# --- In-memory store (replace with secure database in production) ---

items_db: dict[str, ItemResponse] = {}


# --- Endpoints ---


@router.get("/items", response_model=list[ItemResponse])
async def list_items(
    skip: int = Query(0, ge=0, description="Number of items to skip"),
    limit: int = Query(20, ge=1, le=100, description="Maximum items to return"),
):
    """List items with pagination."""
    items = list(items_db.values())
    return items[skip : skip + limit]


@router.post("/items", response_model=ItemResponse, status_code=201)
async def create_item(item: ItemCreate):
    """Create a new item with validated input."""
    item_id = str(uuid.uuid4())
    new_item = ItemResponse(
        id=item_id,
        name=item.name,
        description=item.description,
        price=item.price,
    )
    items_db[item_id] = new_item
    logger.info(f"Item created: id={item_id}")
    return new_item


@router.get("/items/{item_id}", response_model=ItemResponse)
async def get_item(item_id: str):
    """Get item by ID."""
    # Validate UUID format to prevent injection
    try:
        uuid.UUID(item_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid item ID format")

    if item_id not in items_db:
        raise HTTPException(status_code=404, detail="Item not found")

    return items_db[item_id]


@router.delete("/items/{item_id}", status_code=204)
async def delete_item(item_id: str):
    """Delete item by ID."""
    try:
        uuid.UUID(item_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid item ID format")

    if item_id not in items_db:
        raise HTTPException(status_code=404, detail="Item not found")

    del items_db[item_id]
    logger.info(f"Item deleted: id={item_id}")
