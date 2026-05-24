import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../api/types/vision_types.dart';
import '../providers/vision_provider.dart';
import '../widgets/vision/draft_review_card.dart';

enum _Step { modeSelect, videoCapture, stillsCapture, narration, processing, review }

class CaptureScreen extends ConsumerStatefulWidget {
  const CaptureScreen({super.key});

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen> {
  _Step _step = _Step.modeSelect;
  String? _sessionId;
  DraftProduct? _draft;
  final Set<String> _capturedAngles = {};
  bool _recording = false;
  bool _busy = false;
  String? _error;
  final _recorder = AudioRecorder();
  final _picker = ImagePicker();

  static const _angles = [
    'front', 'rear', 'upc', 'label', 'top', 'bottom',
  ];

  @override
  void dispose() {
    _recorder.dispose();
    if (_sessionId != null) {
      ref.read(visionClientProvider)?.deleteSession(_sessionId!);
    }
    super.dispose();
  }

  Future<void> _startSession() async {
    final client = ref.read(visionClientProvider)!;
    _sessionId = await client.startSession();
  }

  Future<void> _pickAndUploadVideo() async {
    setState(() { _busy = true; _error = null; });
    try {
      final xfile = await _picker.pickVideo(source: ImageSource.camera);
      if (xfile == null) { setState(() => _busy = false); return; }
      await _startSession();
      final client = ref.read(visionClientProvider)!;
      await client.uploadVideo(_sessionId!, File(xfile.path));
      setState(() => _step = _Step.narration);
    } on Exception catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _pickAndUploadStill(String angle) async {
    setState(() { _busy = true; _error = null; });
    try {
      final xfile = await _picker.pickImage(
        source: ImageSource.camera, imageQuality: 90);
      if (xfile == null) { setState(() => _busy = false); return; }
      if (_sessionId == null) await _startSession();
      final client = ref.read(visionClientProvider)!;
      await client.uploadStill(_sessionId!, angle, File(xfile.path));
      setState(() => _capturedAngles.add(angle));
    } on Exception catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _startRecordingNarration() async {
    final permitted = await _recorder.hasPermission();
    if (!permitted) {
      setState(() => _error = 'Microphone permission denied');
      return;
    }
    final dir = await getTemporaryDirectory();
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: '${dir.path}/narration.m4a',
    );
    setState(() => _recording = true);
  }

  Future<void> _stopNarrationAndProceed() async {
    final path = await _recorder.stop();
    setState(() => _recording = false);
    if (path != null && _sessionId != null) {
      final client = ref.read(visionClientProvider)!;
      await client.uploadNarration(_sessionId!, File(path));
    }
    await _finalize();
  }

  Future<void> _finalize() async {
    setState(() { _step = _Step.processing; _busy = true; _error = null; });
    try {
      final client = ref.read(visionClientProvider)!;
      final jobId = await client.finalize(_sessionId!);
      final draft = await client.pollJob(jobId);
      setState(() { _draft = draft; _step = _Step.review; });
    } on Exception catch (e) {
      setState(() { _error = e.toString(); _step = _Step.narration; });
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _commit(CommitRequest req) async {
    setState(() { _busy = true; _error = null; });
    try {
      final client = ref.read(visionClientProvider)!;
      final result = await client.commitProduct(req);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Committed: ${result.sku}')),
      );
      Navigator.of(context).pop();
    } on Exception catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final client = ref.watch(visionClientProvider);
    if (client == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Scan Product')),
        body: const Center(child: Text('Select a server first')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_stepTitle()),
        leading: _step == _Step.review
            ? null
            : IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
      ),
      body: _buildBody(),
    );
  }

  String _stepTitle() {
    switch (_step) {
      case _Step.modeSelect: return 'Scan Product';
      case _Step.videoCapture: return 'Record Video';
      case _Step.stillsCapture: return 'Take Stills';
      case _Step.narration: return 'Add Narration';
      case _Step.processing: return 'Processing…';
      case _Step.review: return 'Review Draft';
    }
  }

  Widget _buildBody() {
    if (_error != null && _step != _Step.processing) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => setState(() => _error = null),
              child: const Text('Try again'),
            ),
          ]),
        ),
      );
    }
    switch (_step) {
      case _Step.modeSelect: return _buildModeSelect();
      case _Step.videoCapture: return _buildVideoCapture();
      case _Step.stillsCapture: return _buildStillsCapture();
      case _Step.narration: return _buildNarration();
      case _Step.processing: return _buildProcessing();
      case _Step.review: return _buildReview();
    }
  }

  Widget _buildModeSelect() => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('How would you like to capture this product?',
          style: TextStyle(fontSize: 16)),
      const SizedBox(height: 24),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _ModeButton(
          icon: Icons.videocam,
          label: 'Video',
          onTap: () => setState(() {
            _step = _Step.videoCapture;
          }),
        ),
        const SizedBox(width: 24),
        _ModeButton(
          icon: Icons.photo_camera,
          label: 'Stills',
          onTap: () => setState(() {
            _step = _Step.stillsCapture;
          }),
        ),
      ]),
    ]),
  );

  Widget _buildVideoCapture() => Center(
    child: FilledButton.icon(
      icon: const Icon(Icons.videocam),
      label: const Text('Record 360° rotation'),
      onPressed: _busy ? null : _pickAndUploadVideo,
    ),
  );

  Widget _buildStillsCapture() => Column(children: [
    const Padding(
      padding: EdgeInsets.all(16),
      child: Text('Tap each angle to capture. At least one required.'),
    ),
    Expanded(
      child: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        children: _angles.map((angle) {
          final done = _capturedAngles.contains(angle);
          return GestureDetector(
            onTap: _busy ? null : () => _pickAndUploadStill(angle),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: done ? Colors.green : Colors.grey,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(done ? Icons.check_circle : Icons.camera_alt,
                      color: done ? Colors.green : Colors.grey,
                      size: 36),
                  const SizedBox(height: 8),
                  Text(angle,
                      style: TextStyle(
                          color: done ? Colors.green : null,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    ),
    Padding(
      padding: const EdgeInsets.all(16),
      child: FilledButton(
        onPressed: (_capturedAngles.isEmpty || _busy)
            ? null
            : () => setState(() => _step = _Step.narration),
        child: const Text('Continue'),
      ),
    ),
  ]);

  Widget _buildNarration() => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('Optional: narrate the product aloud',
          style: TextStyle(fontSize: 16)),
      const SizedBox(height: 24),
      GestureDetector(
        onTap: _recording ? _stopNarrationAndProceed : _startRecordingNarration,
        child: CircleAvatar(
          radius: 40,
          backgroundColor: _recording ? Colors.red : Colors.blue,
          child: Icon(
            _recording ? Icons.stop : Icons.mic,
            color: Colors.white, size: 36,
          ),
        ),
      ),
      const SizedBox(height: 12),
      Text(_recording ? 'Tap to stop' : 'Tap to record'),
      const SizedBox(height: 24),
      TextButton(
        onPressed: _recording ? null : _finalize,
        child: const Text('Skip narration'),
      ),
    ]),
  );

  Widget _buildProcessing() => const Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      CircularProgressIndicator(),
      SizedBox(height: 16),
      Text('Analysing product…'),
    ]),
  );

  Widget _buildReview() => DraftReviewCard(
    draft: _draft!,
    onCommit: _commit,
    onCancel: () => Navigator.of(context).pop(),
  );
}

class _ModeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ModeButton(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      CircleAvatar(radius: 32, child: Icon(icon, size: 32)),
      const SizedBox(height: 8),
      Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    ]),
  );
}
