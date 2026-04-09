from pydantic import BaseModel


class UploadMetadata(BaseModel):
    title: str
    description: str
    video_s3_key: str
    video_id: str
    visibility: str