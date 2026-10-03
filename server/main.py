import os
import uuid
from pathlib import Path
from threading import Lock

from dotenv import load_dotenv
from fastapi import BackgroundTasks, FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel
from google import genai

load_dotenv()

BASE_DIR = Path(__file__).resolve().parent
OUTPUT_DIR = BASE_DIR / "output"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

IMAGE_MODEL = "gemini-3.1-flash-image-preview"
VIDEO_MODEL = "veo-3.1-generate-preview"

app = FastAPI(title="Nono21 API", version="1.0.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)
app.mount("/media", StaticFiles(directory=OUTPUT_DIR), name="media")

jobs = {}
jobs_lock = Lock()


class GenerateRequest(BaseModel):
    prompt: str


def set_job(job_id: str, **values):
    with jobs_lock:
        jobs.setdefault(job_id, {}).update(values)


def generate_job(job_id: str, prompt: str):
    try:
        if not os.getenv("GEMINI_API_KEY"):
            raise RuntimeError("GEMINI_API_KEY is not configured on the server.")

        client = genai.Client()

        set_job(job_id, status="generating_image", message="Generating image with Nano Banana 2.")
        image_response = client.models.generate_content(
            model=IMAGE_MODEL,
            contents=prompt,
            config={"response_modalities": ["IMAGE"]},
        )
        if not image_response.parts:
            raise RuntimeError("Nano Banana 2 returned no image.")

        image = image_response.parts[0].as_image()
        image_name = f"{job_id}.png"
        image.save(str(OUTPUT_DIR / image_name))

        set_job(
            job_id,
            status="generating_video",
            message="Generating video with Veo 3.1. This can take some time.",
            image_url=f"/media/{image_name}",
        )

        operation = client.models.generate_videos(
            model=VIDEO_MODEL,
            prompt=prompt,
            image=image,
        )

        import time
        while not operation.done:
            time.sleep(10)
            operation = client.operations.get(operation)

        if getattr(operation, "error", None):
            raise RuntimeError(str(operation.error))

        generated = operation.response.generated_videos
        if not generated:
            raise RuntimeError("Veo 3.1 returned no video.")

        video_name = f"{job_id}.mp4"
        client.files.download(
            file=generated[0].video,
            destination=str(OUTPUT_DIR / video_name),
        )

        set_job(
            job_id,
            status="completed",
            message="Video generation completed.",
            video_url=f"/media/{video_name}",
        )
    except Exception as exc:
        set_job(job_id, status="failed", message=str(exc))


@app.get("/health")
def health():
    return {"ok": True, "service": "nono21"}


@app.post("/generate")
def generate(request: GenerateRequest, background_tasks: BackgroundTasks):
    prompt = request.prompt.strip()
    if not prompt:
        raise HTTPException(status_code=400, detail="Prompt cannot be empty.")

    job_id = uuid.uuid4().hex
    set_job(job_id, status="queued", message="Job queued.")
    background_tasks.add_task(generate_job, job_id, prompt)
    return {"job_id": job_id, "status": "queued"}


@app.get("/jobs/{job_id}")
def job_status(job_id: str):
    with jobs_lock:
        job = jobs.get(job_id)
    if job is None:
        raise HTTPException(status_code=404, detail="Job not found.")
    return {"job_id": job_id, **job}
