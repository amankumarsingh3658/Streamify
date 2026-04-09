# 🎬 Video Streaming Platform (Microservices Architecture)

A scalable video streaming platform built using **Python microservices**, **AWS S3**, **ECS**, **ECR**, and **Flutter frontend**.
The system processes uploaded videos, transcodes them for **Adaptive Bitrate Streaming**, and serves them efficiently using **Redis caching** and **CDN delivery**.

---

# 🏗️ Architecture Overview

The platform consists of **3 Python microservices**:

* **Backend Service (FastAPI)** – API layer, authentication, metadata, upload pipeline
* **Consumer Service** – Polls SQS and triggers ECS transcoding tasks
* **Transcoder Service** – Transcodes videos into adaptive bitrate streams (DASH)

Frontend is built using **Flutter**.

Infrastructure uses:

* AWS S3 (video storage)
* AWS SQS (event queue)
* AWS ECS (task execution)
* AWS ECR (container registry)
* AWS Cognito (authentication)
* Redis (caching)
* PostgreSQL (database)
* CDN (fast video delivery)

---

# ⚙️ Tech Stack

## Backend

* FastAPI (Docker)
* PostgreSQL (Docker)
* Redis (Docker)
* AWS S3
* AWS SQS
* AWS ECS
* AWS ECR
* AWS Cognito

## Video Processing

* FFmpeg
* Dash Adaptive Bitrate Streaming
* Multi-resolution transcoding

## Frontend

* Flutter

## Infrastructure

* Docker
* AWS ECS Fargate
* AWS Cloud CDN
* Redis caching layer

---

# 📦 Microservices

## 1. Backend Service (FastAPI)

Responsibilities:

* User authentication (AWS Cognito)
* Video upload API
* Generate S3 upload URLs
* Store video metadata in PostgreSQL
* Push message to SQS after upload
* Serve video playback metadata
* Redis caching for faster fetch

### Backend Flow

1. User logs in via Cognito
2. Upload request sent to backend
3. Backend generates pre-signed S3 URL
4. Client uploads video directly to S3
5. Backend pushes message to SQS

---

## 2. Consumer Service

Responsibilities:

* Poll SQS queue
* Read uploaded video events
* Spin up ECS task
* Pass video metadata to transcoder container

### Consumer Flow

1. Poll SQS queue
2. Receive video upload event
3. Start ECS task
4. Run Transcoder container
5. Pass S3 input video location

---

## 3. Transcoder Service (ECS Task)

Responsibilities:

* Download video from S3
* Transcode to multiple resolutions
* Generate DASH playlist
* Upload output to S3
* Update video status to completed

### Transcoding Output

Adaptive bitrate Dash:

* 360p
* 720p
* 1080p

After completion:

* Upload to S3
* Update DB status = `completed`
* Clear Redis cache

---

# 🔄 Full Video Pipeline

```
Flutter App
    ↓
FastAPI Backend
    ↓
S3 Upload (Presigned URL)
    ↓
SQS Message
    ↓
Consumer Service
    ↓
ECS Task Spawned
    ↓
Transcoder Service
    ↓
FFmpeg Adaptive Transcoding
    ↓
Upload to S3
    ↓
Update PostgreSQL
    ↓
Redis Cache Invalidation
    ↓
CDN Delivery
```

---

# 🗄️ Database (PostgreSQL)

Video Table:

* id
* title
* description
* s3_input_url
* thumbnail_url
* duration
* status
* created_at

Status:

```
UPLOADED
PROCESSING
COMPLETED
FAILED
```

---

# ⚡ Redis Usage

Redis is used for:

* Video metadata caching
* Thumbnail caching
* Trending videos cache
* Playback metadata cache

This reduces DB load and improves response latency.

---

# 🌍 CDN

CDN is used to serve:

* DASH playlists
* Video segments
* Thumbnails

This ensures:

* Low latency playback
* Global distribution
* Reduced S3 cost

---

# 🔐 Authentication

Authentication is handled using:

AWS Cognito

Flow:

```
Flutter App → Cognito Login
                ↓
            JWT Token
                ↓
        FastAPI Authorization
```

---

# 🐳 Docker Services

Local development includes:

* Backend
* PostgreSQL
* Redis
* Consumer
* Transcoder

---

# 🚀 Deployment

Each service is deployed as:

Backend → ECS Service
Consumer → ECS Service
Transcoder → ECS Task (On-demand)

Images stored in:

AWS ECR

---

# 📁 Project Structure

```
video-platform/
│
├── backend/
│   └── FastAPI service
│
├── consumer/
│   └── SQS polling service
│
├── transcoder/
│   └── FFmpeg processing service
│
├── flutter_app/
│   └── Frontend
│
├── docker/
│
└── README.md
```

---

# 🎥 Features

✅ Video Upload
✅ Adaptive Bitrate Streaming
✅ DASH Playback
✅ AWS S3 Storage
✅ ECS Auto Scaling Tasks
✅ Redis Caching
✅ CDN Delivery
✅ Cognito Authentication
✅ Microservices Architecture
✅ Dockerized Deployment

---

# 📈 Scalability

This architecture supports:

* Parallel transcoding
* Unlimited uploads
* Horizontal scaling
* Event-driven processing
* Low latency playback

---

# 🧠 Future Improvements

* Live streaming support
* WebRTC streaming
* Video analytics
* AI thumbnail generation
* Auto captions
* Video recommendations

---

# 👨‍💻 Author

Built using Python microservices + AWS cloud architecture.
