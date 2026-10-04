from fastapi import APIRouter, HTTPException, status, Depends
from sqlmodel import select, func

from models import User, Connection, DB_SESSION
from middleware import sign_jwt, decode_jwt, get_user
import forms

router = APIRouter()

@router.post('/login')
async def login(form: forms.LoginForm):
    user = DB_SESSION.exec(select(User).where(User.email == form.email, User.reg_no == form.reg_no)).first()
    if user:
        return {
            "message": "Login successful", 
            "user": {
                "name": user.name,
                "role": user.role,
                "passkey": user.passkey
            },
            "token": sign_jwt({ "id": user.id })
        }
    
    raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail={"message": "Invalid email or registration number"})



def connect_users(user_from, user_to):
    if user_from == user_to:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail={"message": "Cannot connect to self"})
    DB_SESSION.add(Connection(user_from=user_from, user_to=user_to))
    DB_SESSION.add(Connection(user_from=user_to, user_to=user_from))
    DB_SESSION.commit()

@router.post('/connect/qr')
async def connect_qr(form: forms.ConnectQRForm, user_id: int = Depends(get_user)):
    data = decode_jwt(form.qr_data)
    connect_users(user_from=user_id, user_to=data.get("id"))

    return { "message": "Connnected Successfully" }

@router.post('/connect')
async def connect(form: forms.ConnectForm, user_id: int = Depends(get_user)):
    user = DB_SESSION.exec(select(User).where(User.email == form.email, User.passkey == form.passkey)).first()
    if user:
        connect_users(user_from=user_id, user_to=user.id)
        return { "message": "Connnected Successfully" }
    else:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail={"message": "Invalid email or passkey"})



@router.get('/leaderboard')
async def leaderboard():
    users = DB_SESSION.exec(
        select(User, func.count(Connection.id).label("connections"))
        .join(Connection, User.id == Connection.user_from)
        .group_by(User.id)
        .order_by(func.count(Connection.id).desc())
    ).all()

    leaderboard = [
        {
            "name": user.name,
            "role": user.role,
            "connections": connections
        }
        for user, connections in users
    ]

    return { "leaderboard": leaderboard }