import os
from typing import Optional

from databases import Database
import sqlalchemy

# Database URL: prefer environment variable `DATABASE_URL`, fallback to the
# in-cluster/postgres values used in this project for convenience.
def _build_from_env():
    user = os.getenv("DB_USER")
    password = os.getenv("DB_PASSWORD")
    host = os.getenv("DB_HOST")
    port = os.getenv("DB_PORT")
    name = os.getenv("DB_NAME")
    if user and password and host and port and name:
        return f"postgresql://{user}:{password}@{host}:{port}/{name}"
    return None


DATABASE_URL = os.getenv("DATABASE_URL") or _build_from_env() or (
    "postgresql://miapp_user:MiPasswordApp123@mi-postgres-primary.default.svc.cluster.local:5432/miapp"
)

database = Database(DATABASE_URL)

metadata = sqlalchemy.MetaData()

items = sqlalchemy.Table(
    "items",
    metadata,
    sqlalchemy.Column("id", sqlalchemy.Integer, primary_key=True),
    sqlalchemy.Column("item", sqlalchemy.String(length=255), nullable=False),
    sqlalchemy.Column("descripcion", sqlalchemy.Text, nullable=True),
)

async def connect():
    """Connect the database and ensure the `items` table exists."""
    await database.connect()
    # Create table if it doesn't exist using a raw SQL statement. This avoids
    # adding sync-only SQLAlchemy DB drivers to the runtime.
    query = """
    CREATE TABLE IF NOT EXISTS items (
      id SERIAL PRIMARY KEY,
      item VARCHAR(255) NOT NULL,
      descripcion TEXT
    );
    """
    await database.execute(query=query)

async def disconnect():
    await database.disconnect()

async def get_items():
    query = items.select()
    return await database.fetch_all(query)

async def create_item(item: str, descripcion: Optional[str] = None):
    # Use RETURNING to get the assigned id when supported by the DB.
    query = items.insert().values(item=item, descripcion=descripcion).returning(items.c.id)
    row = await database.fetch_one(query)
    if row is None:
        # Fallback: try an execute and return no id
        await database.execute(items.insert().values(item=item, descripcion=descripcion))
        return {"id": None, "item": item, "descripcion": descripcion}
    return {"id": row["id"], "item": item, "descripcion": descripcion}
