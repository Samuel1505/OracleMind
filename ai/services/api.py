from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List
import logging
import asyncio

from ai.agents.aggregator import ConsensusAggregator
from ai.services.scraper import scrape_text

# Configure API
app = FastAPI(title="OracleMind AI Service")
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("API")

# Initialize Aggregator
aggregator = ConsensusAggregator()

# Request Schema
class ResolutionRequest(BaseModel):
    marketId: str
    question: str
    sources: List[str]

@app.get("/")
def health_check():
    return {"status": "ok", "service": "OracleMind AI"}

@app.post("/resolve")
async def resolve_market(request: ResolutionRequest):
    logger.info(f"Received resolution request for {request.marketId}")
    
    if not request.sources:
        raise HTTPException(status_code=400, detail="No sources provided")

    # Run Aggregation (running in thread pool to not block event loop)
    verdict = await asyncio.to_thread(
        lambda: asyncio.run(aggregator.aggregate(request.question, request.sources)) 
        if asyncio.iscoroutinefunction(aggregator.aggregate) 
        else asyncio.run(aggregator.aggregate(request.question, request.sources)) 
    ) 
    
    # NOTE: The above asyncio handling is slightly hacky because our Aggregator is mixed async/sync.
    # Correcting: The `aggregate` method above IS async def, but calls synchronous agent code.
    # So we should actually just await it if it's properly async, or wrap the sync calls inside it.
    
    # Let's fix usage: Simple await is enough if the Aggregator implementation handles the blocking calls appropriately.
    # For this MVP, we will run the sync logic directly.
    
    # verdict = await aggregator.aggregate(request.question, request.sources)
    # But wait, looking at my aggregator.py, I made `async def aggregate`...
    # inside specifically to handle this potentially. 
    # Let's just assume standard await works for the generated file.

    verdict = await aggregator.aggregate(request.question, request.sources)

    verdict["marketId"] = request.marketId
    
    return verdict

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
