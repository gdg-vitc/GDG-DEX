import jwt, os
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

security = HTTPBearer()

def sign_jwt(data: dict):
    return jwt.encode(data, os.environ["SECRET_KEY"], algorithm="HS256")

def decode_jwt(token: str):
    try:
        payload = jwt.decode(token, os.environ["SECRET_KEY"], algorithms=["HS256"])
        return payload
    except jwt.InvalidTokenError:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, detail={"message": "Credential validation failed"})

def get_user(credentials: HTTPAuthorizationCredentials = Depends(security)):
    if not credentials:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, detail={"message": "Unauthorized access"})
    try:
        payload = jwt.decode(credentials.credentials, os.environ["SECRET_KEY"], algorithms=["HS256"])
        return payload.get("id")
    
    except jwt.InvalidTokenError:
        raise HTTPException(status.HTTP_400_BAD_REQUEST, detail={"message": "Credential validation failed"})
