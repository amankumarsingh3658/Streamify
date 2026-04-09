from fastapi import HTTPException
import json

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import or_

from db.db import get_db
from db.middleware.auth_middleware import get_current_user
from db.models.video import ProcessingStatus, Video, VisibilityStatus
from db.redis_db import redis_client


router = APIRouter()

@router.get("/all")
def get_all_videos(db: Session = Depends(get_db) , user = Depends(get_current_user)):
    try:
        videos = db.query(Video).filter(Video.is_processing == ProcessingStatus.COMPLETED, Video.visibility == VisibilityStatus.PUBLIC).all()
        return videos;
    except Exception as e:
        raise HTTPException(500 , str(e))
    
@router.get("/")
def get_video_info(video_id: str, db: Session = Depends(get_db), user = Depends(get_current_user)):
    try:
        cache_key = f"video:{video_id}"
        cached_data = redis_client.get(cache_key)

        if(cached_data):
            return json.loads(cached_data)
        video = db.query(Video).filter(
                Video.id == video_id,
                or_(
                    Video.visibility == VisibilityStatus.PUBLIC,
                    Video.visibility == VisibilityStatus.UNLISTED
                ),
                Video.is_processing == ProcessingStatus.COMPLETED
            ).first()
        if not video:
            raise HTTPException(404 , "Video not found")
        
        print(video.to_dict())
        redis_client.setex(cache_key , 3600 , json.dumps(video.to_dict()))
        return video
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(500 , str(e))
    
@router.put("/")
def update_video_status_by_id(video_id: str , db: Session = Depends(get_db)):
    try:
        video = db.query(Video).filter(Video.id == video_id).first()
        print(video_id)
        if not video:
                raise HTTPException(404 , "Video not found")
        video.is_processing = ProcessingStatus.COMPLETED
        db.commit()
        db.refresh(video)
        return video
    except Exception as e:
        raise HTTPException(500 , str(e))