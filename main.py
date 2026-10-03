import os
import sys
import time

from google import genai
from dotenv import load_dotenv

load_dotenv()

PROMPT = "Panning wide shot of a calico kitten sleeping in the sunshine"
IMAGE_MODEL = "gemini-3.1-flash-image-preview"
VIDEO_MODEL = "veo-3.1-generate-preview"
OUTPUT_IMAGE = "nano_banana_2.png"
OUTPUT_VIDEO = "veo3.1_with_image_input.mp4"


def main():
    if not os.getenv("GEMINI_API_KEY"):
        raise SystemExit(
            "GEMINI_API_KEY is not set. Copy .env.example to .env and add your API key."
        )

    client = genai.Client()

    print("1/2 Generating image with Nano Banana 2...")
    image_response = client.models.generate_content(
        model=IMAGE_MODEL,
        contents=PROMPT,
        config={"response_modalities": ["IMAGE"]},
    )

    if not image_response.parts:
        raise RuntimeError("Nano Banana 2 returned no image parts.")

    image = image_response.parts[0].as_image()
    image.save(OUTPUT_IMAGE)
    print(f"Image saved to {OUTPUT_IMAGE}")

    print("2/2 Starting Veo 3.1 image-to-video generation...")
    operation = client.models.generate_videos(
        model=VIDEO_MODEL,
        prompt=PROMPT,
        image=image,
    )

    while not operation.done:
        print("Waiting for video generation to complete...")
        time.sleep(10)
        operation = client.operations.get(operation)

    if getattr(operation, "error", None):
        raise RuntimeError(f"Video generation failed: {operation.error}")

    generated_videos = operation.response.generated_videos
    if not generated_videos:
        raise RuntimeError("Veo 3.1 returned no generated video.")

    video = generated_videos[0]
    client.files.download(file=video.video, destination=OUTPUT_VIDEO)
    print(f"Video saved to {OUTPUT_VIDEO}")


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        sys.exit("\nInterrupted.")
