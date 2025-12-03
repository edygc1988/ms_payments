from fastapi import FastAPI
import logging

logger = logging.getLogger("ms_payments")
logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s - %(message)s")

app = FastAPI()


@app.on_event("startup")
async def on_startup():
    app.state.started = True
    logger.info("Application startup: state.started=True")


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
    # Add real readiness checks here (DB, queues, etc.) if needed
    logger.info("Readiness probe called - OK")
    return {"status": "ready"}
