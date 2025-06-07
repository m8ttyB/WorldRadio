from fastapi import FastAPI, APIRouter, HTTPException
from dotenv import load_dotenv
from starlette.middleware.cors import CORSMiddleware
from motor.motor_asyncio import AsyncIOMotorClient
import os
import logging
from pathlib import Path
from pydantic import BaseModel, Field
from typing import List, Optional
import uuid
from datetime import datetime
import httpx
import asyncio


ROOT_DIR = Path(__file__).parent
load_dotenv(ROOT_DIR / '.env')

# MongoDB connection
mongo_url = os.environ['MONGO_URL']
client = AsyncIOMotorClient(mongo_url)
db = client[os.environ['DB_NAME']]

# Create the main app without a prefix
app = FastAPI()

# Create a router with the /api prefix
api_router = APIRouter(prefix="/api")


# Define Models
class StatusCheck(BaseModel):
    id: str = Field(default_factory=lambda: str(uuid.uuid4()))
    client_name: str
    timestamp: datetime = Field(default_factory=datetime.utcnow)

class StatusCheckCreate(BaseModel):
    client_name: str

# Add your routes to the router instead of directly to app
@api_router.get("/")
async def root():
    return {"message": "Hello World"}

@api_router.post("/status", response_model=StatusCheck)
async def create_status_check(input: StatusCheckCreate):
    status_dict = input.dict()
    status_obj = StatusCheck(**status_dict)
    _ = await db.status_checks.insert_one(status_obj.dict())
    return status_obj

@api_router.get("/status", response_model=List[StatusCheck])
async def get_status_checks():
    status_checks = await db.status_checks.find().to_list(1000)
    return [StatusCheck(**status_check) for status_check in status_checks]

# Include the router in the main app
app.include_router(api_router)

# Radio Browser API proxy endpoints
RADIO_API_BASE = "https://de1.api.radio-browser.info"

@api_router.get("/test")
async def test_route():
    return {"status": "test successful"}

@api_router.get("/radio/stations/popular")
async def get_popular_stations(limit: int = 100):
    """Get popular radio stations"""
    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.get(
                f"{RADIO_API_BASE}/json/stations/topvote",
                params={"limit": limit, "hidebroken": "true"},
                headers={"User-Agent": "GlobalRadioApp/1.0"}
            )
            response.raise_for_status()
            return response.json()
    except Exception as e:
        logger.error(f"Error fetching popular stations: {e}")
        raise HTTPException(status_code=500, detail="Failed to fetch stations")

@api_router.get("/radio/stations/search")
async def search_stations(
    name: Optional[str] = None,
    country: Optional[str] = None,
    limit: int = 100
):
    """Search radio stations"""
    try:
        params = {"limit": limit, "hidebroken": "true"}
        if name:
            params["name"] = name
        if country:
            params["country"] = country
            
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.get(
                f"{RADIO_API_BASE}/json/stations/search",
                params=params,
                headers={"User-Agent": "GlobalRadioApp/1.0"}
            )
            response.raise_for_status()
            return response.json()
    except Exception as e:
        logger.error(f"Error searching stations: {e}")
        raise HTTPException(status_code=500, detail="Failed to search stations")

@api_router.get("/radio/countries")
async def get_countries():
    """Get list of countries with radio stations"""
    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.get(
                f"{RADIO_API_BASE}/json/countries",
                params={"hidebroken": "true"},
                headers={"User-Agent": "GlobalRadioApp/1.0"}
            )
            response.raise_for_status()
            return response.json()
    except Exception as e:
        logger.error(f"Error fetching countries: {e}")
        raise HTTPException(status_code=500, detail="Failed to fetch countries")

@api_router.post("/radio/stations/{station_uuid}/click")
async def register_station_click(station_uuid: str):
    """Register a click for a radio station"""
    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.post(
                f"{RADIO_API_BASE}/json/url/{station_uuid}",
                headers={"User-Agent": "GlobalRadioApp/1.0"}
            )
            return {"success": True}
    except Exception as e:
        logger.warning(f"Error registering click for {station_uuid}: {e}")
        return {"success": False}

app.add_middleware(
    CORSMiddleware,
    allow_credentials=True,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

@app.on_event("shutdown")
async def shutdown_db_client():
    client.close()
