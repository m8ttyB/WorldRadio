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


# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

ROOT_DIR = Path(__file__).parent
load_dotenv(ROOT_DIR / '.env')

# Radio Browser API proxy endpoints - try multiple servers
RADIO_API_SERVERS = [
    "https://nl.api.radio-browser.info",
    "https://de1.api.radio-browser.info", 
    "https://at1.api.radio-browser.info"
]

def get_sample_radio_data(endpoint: str) -> list:
    """Return sample data when all API servers fail"""
    if "topvote" in endpoint:
        return [{"name": "Sample Station", "url": "http://example.com/stream"}]
    elif "search" in endpoint:
        return [{"name": "Sample Search Result", "url": "http://example.com/stream"}]
    elif "countries" in endpoint:
        return [{"name": "Sample Country", "stationcount": 100}]
    return []

async def try_radio_api_request(endpoint: str, params: dict = None):
    """Try multiple Radio Browser API servers"""
    for server in RADIO_API_SERVERS:
        try:
            async with httpx.AsyncClient(timeout=15.0) as client:
                response = await client.get(
                    f"{server}{endpoint}",
                    params=params,
                    headers={"User-Agent": "GlobalRadioApp/1.0"}
                )
                if response.status_code == 200:
                    return response.json()
        except Exception as e:
            logger.warning(f"Failed to connect to {server}: {e}")
            continue
    
    # If all servers fail, return sample data
    logger.error("All Radio Browser API servers failed, returning sample data")
    return get_sample_radio_data(endpoint)

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

@api_router.get("/test")
async def test_route():
    return {"status": "test successful"}

@api_router.get("/radio/stations/popular")
async def get_popular_stations(limit: int = 100):
    """Get popular radio stations"""
    try:
        result = await try_radio_api_request(
            "/json/stations/topvote",
            params={"limit": limit, "hidebroken": "true"}
        )
        return result
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
            
        result = await try_radio_api_request(
            "/json/stations/search",
            params=params
        )
        return result
    except Exception as e:
        logger.error(f"Error searching stations: {e}")
        raise HTTPException(status_code=500, detail="Failed to search stations")

@api_router.get("/radio/countries")
async def get_countries():
    """Get list of countries with radio stations"""
    try:
        result = await try_radio_api_request(
            "/json/countries",
            params={"hidebroken": "true"}
        )
        return result
    except Exception as e:
        logger.error(f"Error fetching countries: {e}")
        raise HTTPException(status_code=500, detail="Failed to fetch countries")

@api_router.post("/radio/stations/{station_uuid}/click")
async def register_station_click(station_uuid: str):
    """Register a click for a radio station"""
    try:
        result = await try_radio_api_request(f"/json/url/{station_uuid}")
        return {"success": True}
    except Exception as e:
        logger.warning(f"Error registering click for {station_uuid}: {e}")
        return {"success": False}

# Include the router in the main app
app.include_router(api_router)

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
