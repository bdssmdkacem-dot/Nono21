# Nono21

Nono21 is a small Android + Python test application for the Gemini pipeline:

**Nano Banana 2 → Veo 3.1 image-to-video**

Google's current Veo 3.1 documentation explicitly shows this image-to-video flow: generate an image with `gemini-3.1-flash-image-preview`, then pass that image to `veo-3.1-generate-preview`. citeturn0search0

## Architecture

```
Android phone
    │
    │ HTTP
    ▼
Nono21 FastAPI server
    │
    │ GEMINI_API_KEY stays here
    ▼
Gemini API
    ├── Nano Banana 2 → PNG
    └── Veo 3.1 → MP4 + audio
```

The Android APK **does not contain the Gemini API key**. The key belongs on the server.

## 1. Start the server

From the repository root:

```bash
python -m venv .venv
```

Activate the environment, then:

```bash
pip install -r server/requirements.txt
```

Create `server/.env` from `server/.env.example` and add:

```env
GEMINI_API_KEY=YOUR_REAL_API_KEY
```

Start the server so the phone can reach it:

```bash
uvicorn server.main:app --host 0.0.0.0 --port 8000
```

Test:

```
http://YOUR_COMPUTER_IP:8000/health
```

## 2. Android phone

The Android client is in `android_app/`.

On a real phone, set **Nono21 server URL** to the computer's LAN address, for example:

```
http://192.168.1.20:8000
```

Both devices must be on the same Wi-Fi network and the computer firewall must allow TCP port 8000.

## 3. Build the APK

GitHub Actions automatically creates the missing Flutter Android platform files and builds a release APK.

Run the **Android APK** workflow manually from the Actions tab, or push to `main`.

The generated APK is uploaded as the workflow artifact `nono21-release-apk`.

## Security

Never put `GEMINI_API_KEY` in Flutter, the APK, GitHub source files, or a public frontend. Keep it only in the server environment.

## Current generation

Default prompt:

```
Panning wide shot of a calico kitten sleeping in the sunshine
```

The server returns a job immediately. The Android app polls the job until the image is available and then until Veo 3.1 finishes.

Veo 3.1 generation is asynchronous and can take time. Google documents 8-second generation, native audio, and image-to-video input for Veo 3.1. citeturn0search0
