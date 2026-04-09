from fastapi import APIRouter, Cookie, Depends, HTTPException, Response
import boto3
from db.db import get_db
from db.middleware.auth_middleware import get_current_user
from db.models.user import User
from helper.auth_helper import get_secret_hash
from pydantic_models.auth_model import ConfirmSignupRequest, LoginRequest, SignupRequest
from secret_keys import SecretKeys
from sqlalchemy.orm import Session


router = APIRouter()
secret_keys = SecretKeys()

COGNITO_CLIENT_ID = secret_keys.COGNITO_CLIENT_ID
COGNITO_CLIENT_SECRET = secret_keys.COGNITO_CLIENT_SECRET
REGION_NAME = secret_keys.REGION_NAME

cognito_client = boto3.client("cognito-idp" , region_name=REGION_NAME)

@router.post("/signup")
def signup_user(data: SignupRequest , db: Session = Depends(get_db)):
    try:
        secret_hash=get_secret_hash(data.email , COGNITO_CLIENT_ID , COGNITO_CLIENT_SECRET)
        cognito_response = cognito_client.sign_up(
            ClientId=COGNITO_CLIENT_ID,
            SecretHash=secret_hash,
            Username=data.email,
            Password=data.password,
            UserAttributes=[
                {"Name":"email","Value":data.email},
                {"Name":"name","Value":data.name},
            ]
        )

        cognito_sub = cognito_response.get("UserSub")

        if not cognito_sub:
            raise HTTPException(400 , "Cognito did not return a valid user sub")
        
        new_user = User(
        name=data.name,
        email=data.email,
        cognito_sub=cognito_sub
        )
        
        db.add(new_user)

        db.commit()

        db.refresh(new_user)

        return {"message":"Signup Successful. Please verify your email if required"}
    except Exception as e:
        raise HTTPException(400, f"Cognito Exception {e}")
    
@router.post("/login")
def login_user(data: LoginRequest, response: Response):
    try:
        secret_hash = get_secret_hash(data.email , COGNITO_CLIENT_ID , COGNITO_CLIENT_SECRET)
        cognito_response= cognito_client.initiate_auth(
            ClientId=COGNITO_CLIENT_ID,
            AuthFlow="USER_PASSWORD_AUTH",
            AuthParameters={
                "USERNAME":data.email,
                "PASSWORD":data.password,
                "SECRET_HASH":secret_hash,
            }
        )

        auth_result = cognito_response.get("AuthenticationResult")

        if not auth_result:
            raise HTTPException(400 , "Incorrect Cognito Response")

        access_token = auth_result.get("AccessToken")
        refresh_token = auth_result.get("RefreshToken")

        response.set_cookie(key="access_token" , value=access_token , httponly=True , secure=True)
        response.set_cookie(key="refresh_token" , value=refresh_token , httponly=True , secure=True)


        return {"message":"User Logged In Successfully"}
    except Exception as e:
        raise HTTPException(400, f"Cognito Exception {e}")

@router.post("/confirm-signup")
def confirm_signup(data: ConfirmSignupRequest):
    try:
        secret_hash = get_secret_hash(data.email , COGNITO_CLIENT_ID , COGNITO_CLIENT_SECRET)
        cognito_client.confirm_sign_up(
            ClientId=COGNITO_CLIENT_ID,
            Username=data.email,
            ConfirmationCode=data.otp,
            SecretHash=secret_hash
        )
        return {"message":"User Confirmed Successfully"}
    except Exception as e:
        raise HTTPException(400 , f'Cognito Exception {e}')
    
@router.post('/refresh')
def refresh(refresh_token: str = Cookie(None) , response : Response = None , user_cognito_sub: str = Cookie(None)):
    try:
        if not refresh_token or user_cognito_sub:
            raise HTTPException(400 , "Cookies cannot be null")
        secret_hash = get_secret_hash(user_cognito_sub , COGNITO_CLIENT_ID , COGNITO_CLIENT_SECRET)
        cognito_response = cognito_client.initiate_auth(
            ClientId=COGNITO_CLIENT_ID,
            AuthFlow="REFRESH_TOKEN_AUTH",
            AuthParameters={
                "REFRESH_TOKEN":refresh_token,
                "SECRET_HASH": secret_hash
            }
        )
        auth_result = cognito_response.get("AuthenticationResult")

        if not auth_result:
            raise HTTPException(400 , "Incorrect Cognito Response")
        
        access_token = auth_result.get("AccessToken")

        response.set_cookie( key="access_token" , value= access_token , httponly=True , secure=True)

        return {"message": "Access Token Refreshed"}
    except Exception as e:
        raise HTTPException(400 , f"Cognito Signup Exception {e}")
    
@router.get('/me')
def get_user(user= Depends(get_current_user)):
    return {"message":"You are authenticated","user": user}