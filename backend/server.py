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
    "https://de1.api.radio-browser.info",
    "https://nl.api.radio-browser.info", 
    "https://at1.api.radio-browser.info",
    "https://fr1.api.radio-browser.info"
]

def get_sample_radio_data(endpoint: str) -> list:
    """Return comprehensive sample data when all API servers fail"""
    if "topvote" in endpoint or "stations" in endpoint:
        return [
            {
                "stationuuid": "sample-uuid-1",
                "name": "BBC World Service",
                "url": "http://stream.live.vc.bbcmedia.co.uk/bbc_world_service",
                "url_resolved": "http://stream.live.vc.bbcmedia.co.uk/bbc_world_service",
                "country": "United Kingdom",
                "tags": "news,talk,english",
                "votes": 12345,
                "bitrate": 128,
                "codec": "MP3"
            },
            {
                "stationuuid": "sample-uuid-2", 
                "name": "Radio France Inter",
                "url": "http://icecast.radiofrance.fr/franceinter-midfi.mp3",
                "url_resolved": "http://icecast.radiofrance.fr/franceinter-midfi.mp3",
                "country": "France",
                "tags": "news,talk,french",
                "votes": 8765,
                "bitrate": 128,
                "codec": "MP3"
            },
            {
                "stationuuid": "sample-uuid-3",
                "name": "NPR News",
                "url": "http://npr-ice.streamguys1.com/live.mp3",
                "url_resolved": "http://npr-ice.streamguys1.com/live.mp3", 
                "country": "United States",
                "tags": "news,talk,english",
                "votes": 15432,
                "bitrate": 128,
                "codec": "MP3"
            },
            {
                "stationuuid": "sample-uuid-4",
                "name": "Deutsche Welle",
                "url": "http://dw.audiostream.io/dw/1001/mp3/64/stream.mp3",
                "url_resolved": "http://dw.audiostream.io/dw/1001/mp3/64/stream.mp3",
                "country": "Germany",
                "tags": "news,international,english",
                "votes": 9876,
                "bitrate": 64,
                "codec": "MP3"
            },
            {
                "stationuuid": "sample-uuid-5",
                "name": "WNYC FM",
                "url": "http://fm939.wnyc.org/wnycfm-web",
                "url_resolved": "http://fm939.wnyc.org/wnycfm-web",
                "country": "United States",
                "tags": "talk,news,culture",
                "votes": 8543,
                "bitrate": 128,
                "codec": "MP3"
            },
            {
                "stationuuid": "sample-uuid-6",
                "name": "Radio Nederland",
                "url": "http://icecast.omroep.nl/radio1-bb-mp3",
                "url_resolved": "http://icecast.omroep.nl/radio1-bb-mp3",
                "country": "Netherlands",
                "tags": "news,talk,dutch",
                "votes": 7654,
                "bitrate": 128,
                "codec": "MP3"
            },
            {
                "stationuuid": "sample-uuid-7",
                "name": "Jazz FM",
                "url": "http://jazz-wr04.ice.infomaniak.ch/jazz-wr04-128.mp3",
                "url_resolved": "http://jazz-wr04.ice.infomaniak.ch/jazz-wr04-128.mp3",
                "country": "Switzerland",
                "tags": "jazz,music",
                "votes": 6789,
                "bitrate": 128,
                "codec": "MP3"
            },
            {
                "stationuuid": "sample-uuid-8",
                "name": "KCRW",
                "url": "http://kcrw.streamguys1.com/kcrw_192k_mp3_e24",
                "url_resolved": "http://kcrw.streamguys1.com/kcrw_192k_mp3_e24",
                "country": "United States",
                "tags": "eclectic,music,culture",
                "votes": 9123,
                "bitrate": 192,
                "codec": "MP3"
            },
            {
                "stationuuid": "sample-uuid-9",
                "name": "ABC Radio National",
                "url": "http://live-radio02.mediahubaustralia.com/2RNW/mp3/",
                "url_resolved": "http://live-radio02.mediahubaustralia.com/2RNW/mp3/",
                "country": "Australia",
                "tags": "news,talk,culture",
                "votes": 5432,
                "bitrate": 128,
                "codec": "MP3"
            },
            {
                "stationuuid": "sample-uuid-10",
                "name": "CBC Radio One",
                "url": "http://cbc_r1_tor.akacast.akamaistream.net/7/440/451661/v1/rc.akacast.akamaistream.net/cbc_r1_tor",
                "url_resolved": "http://cbc_r1_tor.akacast.akamaistream.net/7/440/451661/v1/rc.akacast.akamaistream.net/cbc_r1_tor",
                "country": "Canada",
                "tags": "news,talk,canadian",
                "votes": 7890,
                "bitrate": 128,
                "codec": "MP3"
            },
            {
                "stationuuid": "sample-uuid-11",
                "name": "Radio Swiss Pop",
                "url": "http://stream.srg-ssr.ch/rsp/mp3_128.m3u",
                "url_resolved": "http://stream.srg-ssr.ch/rsp/mp3_128.m3u",
                "country": "Switzerland",
                "tags": "pop,music",
                "votes": 4567,
                "bitrate": 128,
                "codec": "MP3"
            },
            {
                "stationuuid": "sample-uuid-12",
                "name": "NRK P1",
                "url": "http://lyd.nrk.no/nrk_radio_p1_ostlandssendingen_mp3_h",
                "url_resolved": "http://lyd.nrk.no/nrk_radio_p1_ostlandssendingen_mp3_h",
                "country": "Norway",
                "tags": "news,talk,norwegian",
                "votes": 3456,
                "bitrate": 192,
                "codec": "MP3"
            },
            {
                "stationuuid": "sample-uuid-13",
                "name": "Classic FM",
                "url": "http://media-ice.musicradio.com/ClassicFMMP3",
                "url_resolved": "http://media-ice.musicradio.com/ClassicFMMP3",
                "country": "United Kingdom",
                "tags": "classical,music",
                "votes": 8901,
                "bitrate": 128,
                "codec": "MP3"
            },
            {
                "stationuuid": "sample-uuid-14",
                "name": "Radio Maria",
                "url": "http://dreamsiteradiocp2.com:8002/stream",
                "url_resolved": "http://dreamsiteradiocp2.com:8002/stream",
                "country": "Italy",
                "tags": "religious,italian",
                "votes": 2345,
                "bitrate": 128,
                "codec": "MP3"
            },
            {
                "stationuuid": "sample-uuid-15",
                "name": "Radio Sweden",
                "url": "http://sverigesradio.se/topsy/direkt/132-hi-mp3.m3u",
                "url_resolved": "http://sverigesradio.se/topsy/direkt/132-hi-mp3.m3u",
                "country": "Sweden",
                "tags": "news,talk,swedish",
                "votes": 5678,
                "bitrate": 128,
                "codec": "MP3"
            },
            {
                "stationuuid": "sample-uuid-16",
                "name": "Smooth Jazz",
                "url": "http://player.smoothjazz.com/",
                "url_resolved": "http://player.smoothjazz.com/",
                "country": "United States",
                "tags": "jazz,smooth,instrumental",
                "votes": 6543,
                "bitrate": 128,
                "codec": "MP3"
            },
            {
                "stationuuid": "sample-uuid-17",
                "name": "FIP",
                "url": "http://icecast.radiofrance.fr/fip-midfi.mp3",
                "url_resolved": "http://icecast.radiofrance.fr/fip-midfi.mp3",
                "country": "France",
                "tags": "eclectic,music,french",
                "votes": 7432,
                "bitrate": 128,
                "codec": "MP3"
            },
            {
                "stationuuid": "sample-uuid-18",
                "name": "Radio 4",
                "url": "http://bbcmedia.ic.llnwd.net/stream/bbcmedia_radio4fm_mf_p",
                "url_resolved": "http://bbcmedia.ic.llnwd.net/stream/bbcmedia_radio4fm_mf_p",
                "country": "United Kingdom",
                "tags": "talk,drama,culture",
                "votes": 9876,
                "bitrate": 128,
                "codec": "MP3"
            },
            {
                "stationuuid": "sample-uuid-19",
                "name": "WDR 2",
                "url": "http://wdr-wdr2-ruhrgebiet.icecast.wdr.de/wdr/wdr2/ruhrgebiet/mp3/128/stream.mp3",
                "url_resolved": "http://wdr-wdr2-ruhrgebiet.icecast.wdr.de/wdr/wdr2/ruhrgebiet/mp3/128/stream.mp3",
                "country": "Germany",
                "tags": "pop,german,regional",
                "votes": 4321,
                "bitrate": 128,
                "codec": "MP3"
            },
            {
                "stationuuid": "sample-uuid-20",
                "name": "Triple J",
                "url": "http://live-radio01.mediahubaustralia.com/2TJW/mp3/",
                "url_resolved": "http://live-radio01.mediahubaustralia.com/2TJW/mp3/",
                "country": "Australia",
                "tags": "alternative,rock,youth",
                "votes": 8765,
                "bitrate": 128,
                "codec": "MP3"
            }
        ]
    elif "countries" in endpoint:
        return [
            {"name": "United States", "stationcount": 2500},
            {"name": "Germany", "stationcount": 1200},
            {"name": "United Kingdom", "stationcount": 800},
            {"name": "France", "stationcount": 600},
            {"name": "Canada", "stationcount": 400},
            {"name": "Australia", "stationcount": 350},
            {"name": "Netherlands", "stationcount": 300},
            {"name": "Italy", "stationcount": 280},
            {"name": "Spain", "stationcount": 250},
            {"name": "Sweden", "stationcount": 200},
            {"name": "Norway", "stationcount": 180},
            {"name": "Switzerland", "stationcount": 150},
            {"name": "Austria", "stationcount": 120},
            {"name": "Belgium", "stationcount": 100},
            {"name": "Denmark", "stationcount": 90}
        ]
    return []

async def try_radio_api_request(endpoint: str, params: dict = None):
    """Try multiple Radio Browser API servers with improved error handling"""
    
    # First, try Radio Browser API servers
    for server in RADIO_API_SERVERS:
        try:
            async with httpx.AsyncClient(timeout=8.0) as client:
                response = await client.get(
                    f"{server}{endpoint}",
                    params=params,
                    headers={"User-Agent": "GlobalRadioApp/1.0"}
                )
                if response.status_code == 200:
                    data = response.json()
                    # Ensure we return valid data
                    if isinstance(data, list) and len(data) > 0:
                        logger.info(f"Successfully fetched {len(data)} items from {server}")
                        return data
        except Exception as e:
            logger.warning(f"Failed to connect to {server}: {e}")
            continue
    
    # Try alternative approach with different API endpoints
    alternative_servers = [
        "https://www.radio-browser.info/webservice/json",
        "https://api.radio-browser.info/json"
    ]
    
    for server in alternative_servers:
        try:
            async with httpx.AsyncClient(timeout=8.0) as client:
                response = await client.get(
                    f"{server}{endpoint}",
                    params=params,
                    headers={"User-Agent": "GlobalRadioApp/1.0"}
                )
                if response.status_code == 200:
                    data = response.json()
                    if isinstance(data, list) and len(data) > 0:
                        logger.info(f"Successfully fetched {len(data)} items from alternative server {server}")
                        return data
        except Exception as e:
            logger.warning(f"Failed to connect to alternative server {server}: {e}")
            continue
    
    # If all servers fail, return comprehensive sample data
    logger.error("All Radio Browser API servers failed, returning comprehensive sample data")
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
        
        # If we got sample data, perform local filtering
        if result and len(result) > 0 and result[0].get("stationuuid", "").startswith("sample-uuid"):
            filtered_result = []
            for station in result:
                match = True
                
                # Filter by name (case-insensitive)
                if name and name.lower() not in station.get("name", "").lower():
                    match = False
                
                # Filter by country (case-insensitive)
                if country and country.lower() != station.get("country", "").lower():
                    match = False
                
                if match:
                    filtered_result.append(station)
            
            return filtered_result[:limit]
        
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
        # Try to register with actual API servers
        for server in RADIO_API_SERVERS:
            try:
                async with httpx.AsyncClient(timeout=10.0) as client:
                    response = await client.post(
                        f"{server}/json/url/{station_uuid}",
                        headers={"User-Agent": "GlobalRadioApp/1.0"}
                    )
                    if response.status_code in [200, 201, 204]:
                        return {"success": True}
            except Exception as e:
                logger.warning(f"Failed to register click with {server}: {e}")
                continue
        
        # If all servers fail, just return success (click registration is not critical)
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
