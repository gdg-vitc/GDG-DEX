from pydantic import BaseModel, EmailStr

class LoginForm(BaseModel):
    email: EmailStr
    reg_no: str

class ConnectQRForm(BaseModel):
    qr_data: str

class ConnectForm(BaseModel):
    email: EmailStr
    passkey: str