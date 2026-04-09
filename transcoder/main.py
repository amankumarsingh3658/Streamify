import os
from pathlib import Path
import subprocess
import shutil

import boto3
from secret_keys import SecretKeys
import requests

secret_keys = SecretKeys()


class VideoTranscoder:
    def __init__(self):
        self.s3_client = boto3.client(
            "s3",
            region_name=secret_keys.REGION_NAME,
            aws_access_key_id=secret_keys.AWS_ACCESS_KEY_ID,
            aws_secret_access_key=secret_keys.AWS_SECRET_ACCESS_KEY,
        )

    def _get_content_type(self, filename):
        if filename.endswith(".m3u8"):
            return "application/vnd.apple.mpegurl"   # HLS playlist
        elif filename.endswith(".ts"):
            return "video/MP2T"                      # HLS segment

        elif filename.endswith(".mpd"):
            return "application/dash+xml"            # DASH manifest
        elif filename.endswith(".m4s"):
            return "video/iso.segment"               # DASH segment
        elif filename.endswith(".mp4"):
            return "video/mp4"                       # init segments / fallback

        else:
            return "application/octet-stream"

    # 🔍 Detect if input has audio
    def _has_audio(self, input_path):
        cmd = [
            "ffprobe",
            "-v", "error",
            "-select_streams", "a",
            "-show_entries", "stream=index",
            "-of", "csv=p=0",
            str(input_path)
        ]
        result = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        return bool(result.stdout.strip())

    def download_video(self, local_path):
        self.s3_client.download_file(
            secret_keys.S3_BUCKET,
            secret_keys.S3_KEY,
            str(local_path),
        )

    def transcode_video(self, input_path, output_path):
        print("🎬 Starting transcoding...")

        cmd = [
            "ffmpeg",
            "-y",
            "-i", str(input_path),

            # 🎬 Split + scale
            "-filter_complex",
            "[0:v]split=3[v1][v2][v3];"
            "[v1]scale=640:360[360p];"
            "[v2]scale=1280:720[720p];"
            "[v3]scale=1920:1080[1080p]",

            # 🎥 Video streams
            "-map", "[360p]",
            "-map", "[720p]",
            "-map", "[1080p]",

            # 🔊 Audio
            "-map", "0:a?",

            # 🎥 Encoding
            "-c:v", "libx264",
            "-preset", "veryfast",
            "-profile:v", "high",
            "-level:v", "4.1",
            "-g", "48",
            "-keyint_min", "48",
            "-sc_threshold", "0",

            # 🎯 Bitrates
            "-b:v:0", "1000k",
            "-b:v:1", "4000k",
            "-b:v:2", "8000k",

            # 🔊 Audio
            "-c:a", "aac",
            "-b:a", "128k",

            # 📦 DASH
            "-f", "dash",
            "-seg_duration", "6",
            "-use_template", "1",
            "-use_timeline", "1",
            "-window_size", "5",

            # naming
            "-init_seg_name", "init_$RepresentationID$.m4s",
            "-media_seg_name", "chunk_$RepresentationID$_$Number%03d$.m4s",

            # adaptation sets
            "-adaptation_sets", "id=0,streams=v id=1,streams=a",

            f"{str(output_path)}/manifest.mpd",
        ]

        print("🚀 Running FFmpeg...")
        print(" ".join(cmd))

        process = subprocess.run(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE
        )

        if process.returncode != 0:
            print("❌ FFmpeg Error:")
            print(process.stderr.decode())
            raise Exception("Transcoding has failed")

        print("✅ Transcoding completed successfully")

    def upload_files(self, prefix, local_dir):
        for root, _, files in os.walk(local_dir):
            for file in files:
                local_path = os.path.join(root, file)

                # maintain folder structure
                relative_path = os.path.relpath(local_path, local_dir)
                s3_key = f"{prefix}/{relative_path}"

                content_type = self._get_content_type(local_path)

                print(f"⬆️ Uploading: {s3_key}")

                self.s3_client.upload_file(
                    local_path,
                    secret_keys.S3_PROCESSED_VIDEOS_BUCKET,
                    s3_key,
                    ExtraArgs={
                        "ACL": "public-read",
                        "ContentType": content_type,
                    },
                )

    def process_video(self):
        work_dir = Path("/tmp/workspace")
        work_dir.mkdir(exist_ok=True)

        input_path = work_dir / "input.mp4"
        output_path = work_dir / "output"
        output_path.mkdir(exist_ok=True)

        try:
            print("⬇️ Downloading video...")
            self.download_video(input_path)

            print("🎬 Starting transcoding...")
            self.transcode_video(input_path, output_path)

            print("☁️ Uploading to S3...")
            self.upload_files(secret_keys.S3_KEY, str(output_path))

            print("🔄 Updating video status in backend...")
            self.update_video_processing_status()

            print("🎉 Pipeline completed successfully")

        finally:
            print("🧹 Cleaning up...")
            if input_path.exists():
                input_path.unlink()
            if output_path.exists():
                shutil.rmtree(output_path)

    def update_video_processing_status(self):
        try:
            response = requests.put(
            f"{secret_keys.BACKEND_URL}/videos?video_id={secret_keys.S3_KEY}",
            )
            print(f"✅ Updated video status: {response.json()}")
            return response.json()
        except Exception as e:
            print(f"❌ Failed to update video status: {e}")



if __name__ == "__main__":
    VideoTranscoder().process_video()