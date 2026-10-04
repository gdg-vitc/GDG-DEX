from fastapi import FastAPI
from contextlib import asynccontextmanager

from models import init_db

@asynccontextmanager
async def lifespan(_: FastAPI):
    await init_db()
    yield

app = FastAPI(title="GDG-DEX", lifespan=lifespan)

from views import router
app.include_router(router, prefix="/api")