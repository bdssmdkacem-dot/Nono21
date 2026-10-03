# Nono21

Minimal Python test project for the Gemini API pipeline:

**Nano Banana 2 → Veo 3.1 image-to-video**

The project follows Google's current Gemini API example for generating an image with Nano Banana 2 and using that image as the starting frame for Veo 3.1. See the official Veo documentation for the current API behavior and model availability.

## Requirements

- Python 3.10+
- A Gemini API key with access to the required models
- Internet access

## Setup

### 1. Create a virtual environment

```bash
python -m venv .venv
```

Activate it:

**Windows PowerShell**
```powershell
.\.venv\Scripts\Activate.ps1
```

**macOS/Linux**
```bash
source .venv/bin/activate
```

### 2. Install dependencies

```bash
pip install -r requirements.txt
```

### 3. Configure the API key

Copy `.env.example` to `.env`:

```bash
cp .env.example .env
```

On Windows PowerShell:

```powershell
Copy-Item .env.example .env
```

Then edit `.env`:

```env
GEMINI_API_KEY=YOUR_REAL_API_KEY
```

**Never commit `.env` or your real API key.**

### 4. Run

```bash
python main.py
```

The script:

1. Generates a kitten image with `gemini-3.1-flash-image-preview`.
2. Uses that image as the starting frame for `veo-3.1-generate-preview`.
3. Polls the long-running Veo operation until it completes.
4. Saves the image as `nano_banana_2.png`.
5. Saves the generated video as `veo3.1_with_image_input.mp4`.

Generated media is ignored by Git via `.gitignore`.

## Change the prompt

Edit `PROMPT` in `main.py`:

```python
PROMPT = "Your prompt here"
```

## Important

Video generation is asynchronous and can take time. Veo 3.1 also generates audio natively. Availability, quotas, pricing, and model names can change while these models are in preview, so check the official Google AI documentation before troubleshooting an API error.

Official documentation:
https://ai.google.dev/gemini-api/docs/veo
