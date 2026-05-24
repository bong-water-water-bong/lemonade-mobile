import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../api/types/vision_types.dart';
import '../providers/vision_provider.dart';
import '../widgets/vision/deduce_result_tile.dart';

class DeduceScreen extends ConsumerStatefulWidget {
  const DeduceScreen({super.key});

  @override
  ConsumerState<DeduceScreen> createState() => _DeduceScreenState();
}

class _DeduceScreenState extends ConsumerState<DeduceScreen> {
  bool _voiceMode = false;
  final _queryCtrl = TextEditingController();
  List<DeduceCandidate> _candidates = [];
  String? _error;
  bool _loading = false;
  bool _recording = false;
  final _recorder = AudioRecorder();

  @override
  void dispose() {
    _queryCtrl.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _searchText() async {
    final client = ref.read(visionClientProvider);
    if (client == null) return;
    final q = _queryCtrl.text.trim();
    if (q.isEmpty) return;
    setState(() { _loading = true; _error = null; });
    try {
      final resp = await client.deduceText(q);
      setState(() => _candidates = resp.candidates);
    } on VisionException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _startRecording() async {
    final permitted = await _recorder.hasPermission();
    if (!permitted) {
      setState(() => _error = 'Microphone permission denied');
      return;
    }
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/deduce_query.m4a';
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: path,
    );
    setState(() { _recording = true; _error = null; });
  }

  Future<void> _stopRecordingAndSearch() async {
    final path = await _recorder.stop();
    setState(() => _recording = false);
    if (path == null) return;

    final client = ref.read(visionClientProvider);
    if (client == null) return;
    setState(() { _loading = true; _error = null; });
    try {
      final bytes = await File(path).readAsBytes();
      final resp = await client.deduceAudio(
          Uint8List.fromList(bytes), 'audio/m4a');
      setState(() => _candidates = resp.candidates);
    } on VisionException catch (e) {
      setState(() => _error = e.message);
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final client = ref.watch(visionClientProvider);

    if (client == null) {
      return const Center(child: Text('Select a server first'));
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Text')),
              ButtonSegment(value: true, label: Text('Voice')),
            ],
            selected: {_voiceMode},
            onSelectionChanged: (s) =>
                setState(() { _voiceMode = s.first; _candidates = []; }),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: _voiceMode ? _buildVoiceInput() : _buildTextInput(),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(_error!,
                style: const TextStyle(color: Colors.red)),
          ),
        if (_loading) const LinearProgressIndicator(),
        Expanded(
          child: _candidates.isEmpty && !_loading
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search_off, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('No candidates yet',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: _candidates.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) =>
                      DeduceResultTile(candidate: _candidates[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildTextInput() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _queryCtrl,
            decoration: const InputDecoration(
              hintText: 'e.g. elf bar mango ice 5000',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _searchText(),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: _loading ? null : _searchText,
          child: const Text('Search'),
        ),
      ],
    );
  }

  Widget _buildVoiceInput() {
    return Center(
      child: GestureDetector(
        onTap: _loading
            ? null
            : (_recording ? _stopRecordingAndSearch : _startRecording),
        child: CircleAvatar(
          radius: 36,
          backgroundColor: _recording ? Colors.red : Colors.blue,
          child: Icon(
            _recording ? Icons.stop : Icons.mic,
            color: Colors.white,
            size: 32,
          ),
        ),
      ),
    );
  }
}
