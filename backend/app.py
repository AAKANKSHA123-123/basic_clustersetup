from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional
import os
import uvicorn

app = FastAPI(title="Kubernetes Demo Backend", version="1.0.0")

# Enable CORS for frontend communication
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify actual origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Simple in-memory storage
items = []

# Pydantic models for request/response validation
class ItemCreate(BaseModel):
    name: str
    description: Optional[str] = ""

class ItemResponse(BaseModel):
    id: int
    name: str
    description: str

@app.get("/api/health")
async def health():
    """Health check endpoint"""
    return {"status": "healthy", "service": "backend"}

@app.get("/api/items", response_model=dict)
async def get_items():
    """Get all items"""
    return {"items": items}

@app.post("/api/items", response_model=ItemResponse, status_code=201)
async def add_item(item: ItemCreate):
    """Add a new item"""
    new_item = {
        "id": len(items) + 1,
        "name": item.name,
        "description": item.description or ""
    }
    items.append(new_item)
    return new_item

@app.delete("/api/items/{item_id}")
async def delete_item(item_id: int):
    """Delete an item"""
    global items
    original_count = len(items)
    items = [item for item in items if item['id'] != item_id]
    
    if len(items) == original_count:
        raise HTTPException(status_code=404, detail="Item not found")
    
    return {"message": "Item deleted"}

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5000))
    uvicorn.run(app, host='0.0.0.0', port=port)
