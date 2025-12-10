from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import logging
from typing import List, Optional

import db

logger = logging.getLogger("ms_payments")
logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s - %(message)s")

app = FastAPI()


class ItemCreate(BaseModel):
    item: str
    descripcion: Optional[str] = None


class Item(BaseModel):
    id: int
    item: str
    descripcion: Optional[str] = None


@app.on_event("startup")
async def on_startup():
    app.state.started = True
    logger.info("Application startup: state.started=True")
    # Connect to DB and create table if necessary
    try:
        await db.connect()
        logger.info("Database connected")
    except Exception as e:
        logger.exception("Failed to connect to database: %s", e)


@app.on_event("shutdown")
async def on_shutdown():
    try:
        await db.disconnect()
        logger.info("Database disconnected")
    except Exception:
        logger.exception("Error during database disconnect")


@app.get("/")
async def read_root():
    logger.info("Root endpoint called")
    return {"message": "cu-ms-payments is up and running"}


@app.get("/liveness")
async def liveness():
    logger.info("Liveness probe called - OK")
    return {"status": "alive"}


@app.get("/startup")
async def startup():
    started = getattr(app.state, "started", False)
    logger.info("Startup probe called - started=%s", started)
    if started:
        return {"status": "started"}
    return {"status": "starting"}


@app.get("/readiness")
async def readiness():
    # Basic readiness: check DB connection
    try:
        # perform a simple query
        rows = await db.get_items()
        logger.info("Readiness: DB OK (%d items)", len(rows))
        return {"status": "ready"}
    except Exception as e:
        logger.exception("Readiness check failed: %s", e)
        raise HTTPException(status_code=503, detail="DB not ready")


@app.get("/items", response_model=List[Item])
async def list_items():
    """Return all items from the database."""
    rows = await db.get_items()
    # rows are Mapping objects from `databases`; convert to dicts
    return [ {"id": r["id"], "item": r["item"], "descripcion": r.get("descripcion")} for r in rows ]


@app.post("/items", response_model=Item, status_code=201)
async def create_item_endpoint(payload: ItemCreate):
    """Create an item and return it with its assigned id."""
    try:
        created = await db.create_item(payload.item, payload.descripcion)
        return Item(**created)
    except Exception as e:
        logger.exception("Failed to create item: %s", e)
        raise HTTPException(status_code=500, detail="Failed to create item")
