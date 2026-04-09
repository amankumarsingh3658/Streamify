from sqlalchemy import Column, Enum, ForeignKey, Text
import enum

from db.base import Base

class VisibilityStatus(enum.Enum):
    PRIVATE = "PRIVATE"
    PUBLIC = "PUBLIC"
    UNLISTED = "UNLISTED"

class ProcessingStatus(enum.Enum):
    COMPLETED = "COMPLETED"
    FAILED = "FAILED"
    IN_PROGRESS = "IN_PROGRESS"



class Video(Base):
    __tablename__ = "videos"
    id = Column(Text , primary_key=True)
    title = Column(Text)
    description = Column(Text)
    user_id = Column(Text , ForeignKey("users.cognito_sub"))
    video_s3_key = Column(Text)
    visibility = Column(Enum(VisibilityStatus) , nullable=False , default=VisibilityStatus.PRIVATE)
    is_processing = Column(Enum(ProcessingStatus) , nullable=False , default=ProcessingStatus.IN_PROGRESS)



    def to_dict(self):
        result = {}
        for c in self.__table__.columns:
            value = getattr(self , c.name)
            if isinstance(value , enum.Enum):
                value = value.value
            result[c.name] = value
        return result