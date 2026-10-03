# Nono21 Android

This Flutter app is the phone client. It never contains the Gemini API key.

The app calls the Nono21 FastAPI server, starts a generation job, polls its status, shows the Nano Banana 2 image, and plays the resulting Veo 3.1 video.

## Server URL

On an Android emulator, the default `http://10.0.2.2:8000` points to the development computer.

On a real Android phone, set the server URL in the app to the computer's LAN address, for example:

`http://192.168.1.20:8000`

The computer firewall must allow TCP port 8000 and both devices must be on the same network.
