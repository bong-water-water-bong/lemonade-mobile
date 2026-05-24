# Architecture

> Flutter mobile client for Lemonade Server — community fork extended with Vision Capture and Deduce screens for the lemonade-cashier product pipeline.

## Overview
lemonade-mobile is a Flutter app that connects to a running Lemonade Server instance. The user's fork adds two major subsystems on `feat/vision-cashier`:

```
Flutter App
├── Core (upstream)
│   ├── Chat / LLM interaction
│   ├── Server selection (selectedServerProvider)
│   └── Transcription
└── Vision extension (bong-water-water-bong additions)
    ├── VisionApiClient          → lib/api/vision_client.dart
    ├── visionClientProvider     → lib/providers/vision_provider.dart
    ├── DeduceScreen             → lib/screens/deduce_screen.dart
    ├── CaptureScreen            → lib/screens/capture_screen.dart
    ├── VisionHomeScreen         → lib/screens/vision_home_screen.dart
    └── Widgets                  → lib/widgets/vision/
```

## State Management
Riverpod 2.x with `StateNotifierProvider`. Key providers:
- `selectedServerProvider` — active Lemonade Server URL (upstream)
- `visionClientProvider` — derives `VisionApiClient` from selected server; points to port 8787

## Vision Subsystem (key flow)
```
CaptureScreen
  → POST /session/start         → sessionId
  → POST /capture/video         → (optional)
  → POST /capture/still/{angle} → (multiple angles)
  → POST /capture/audio         → M4A → ffmpeg WAV (server-side)
  → POST /session/finalize      → jobId
  → GET  /jobs/{jobId}/poll     → DraftProduct
  → Review in DraftReviewCard   → POST /products/commit

DeduceScreen
  → text mode: POST /deduce/text
  → voice mode: record M4A → POST /deduce/audio → DeduceResponse
```

## Audio Format
iOS `record` package produces M4A (AAC). The server-side ffmpeg pipeline converts to PCM WAV 16kHz mono before passing to faster-whisper. Do not send raw M4A expecting WAV processing.

## Key Decisions
- **Why Riverpod over Bloc**: upstream uses Riverpod; consistency over preference
- **Why port 8787**: lemonade-vision-server runs on 8787, separate from Lemonade Server's 13305
- **Why lazy session start**: CaptureScreen starts a session only when the first still is uploaded, not on screen open

## Related
- [[README]] — mission and agent handoff
- `lemonade-vision-server` — the FastAPI backend these screens talk to
