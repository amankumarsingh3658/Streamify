
from sqlalchemy import Column, Integer, Text

from db.base import Base


class User(Base):
    __tablename__ = "users"
    id = Column(Integer , primary_key= True , index=True)
    name = Column(Text , nullable= False)
    email = Column(Text , index = True , nullable= False , unique=True)
    cognito_sub = Column(Text , index = True , nullable= False , unique=True)
