# Vision Screens

## CaptureScreen (`lib/screens/capture_screen.dart`)
5-step wizard for scanning a new product into lemonade-cashier inventory.

**Steps** (enum `_Step`):
1. `modeSelect` — choose video or stills mode
2. `videoCapture` — record video (ImagePicker, source: camera)
3. `stillsCapture` — shoot front/back/barcode/label angles
4. `narration` — voice describe the product (records M4A via `record` package)
5. `processing` — polls `GET /jobs/{jobId}/poll` until `DraftProduct` ready
6. `review` — `DraftReviewCard` shows VLM-generated draft; user edits + commits

**Session lifecycle**: session starts lazily on first still upload. `_sessionId` is `null` until `_uploadStill()` is first called.

## DeduceScreen (`lib/screens/deduce_screen.dart`)
Text + voice product lookup using CLIP and ChromaDB similarity search.

**Modes** (SegmentedButton):
- **Text**: type a query → `POST /deduce/text` → `DeduceResponse`
- **Voice**: hold to record → M4A saved to `deduce_query.m4a` → `POST /deduce/audio`

**Result display**: `DeduceResultTile` shows confidence color coding:
- ≥ 0.85: green (high confidence)
- ≥ 0.60: amber (review)
- < 0.60: red (low confidence, manual verify)

## VisionHomeScreen (`lib/screens/vision_home_screen.dart`)
Tab bar with Lookup (DeduceScreen) and Onboard (CaptureScreen) tabs.
Accessible from the chat drawer via `Icons.camera_enhance` tile.

## Adding to Drawer
The Vision entry is inserted in `lib/widgets/chat_drawer.dart` before the Transcription tile. Do not reorder drawer items without updating `chat_drawer.dart`.
