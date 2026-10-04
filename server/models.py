import os
from sqlmodel import SQLModel, Field, Session, create_engine

class User(SQLModel, table=True):
    id: int = Field(default=None, primary_key=True)
    name: str
    email: str
    reg_no: str
    role: str
    passkey: str

class Connection(SQLModel, table=True):
    id: int = Field(default=None, primary_key=True)
    user_from: int = Field(foreign_key="user.id")
    user_to: int = Field(foreign_key="user.id")

    class Meta:
        unique_together = ("user_from", "user_to")

engine = create_engine(os.environ["DATABASE_URL"])

async def init_db():
    SQLModel.metadata.create_all(engine)

DB_SESSION = Session(engine)