import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../api/types/vision_types.dart';

class DraftReviewCard extends StatefulWidget {
  final DraftProduct draft;
  final void Function(CommitRequest) onCommit;
  final VoidCallback onCancel;

  const DraftReviewCard({
    super.key,
    required this.draft,
    required this.onCommit,
    required this.onCancel,
  });

  @override
  State<DraftReviewCard> createState() => _DraftReviewCardState();
}

class _DraftReviewCardState extends State<DraftReviewCard> {
  static const _categories = [
    'disposable_vape', 'e-liquid', 'accessory', 'other',
  ];

  late final TextEditingController _sku;
  late final TextEditingController _brand;
  late final TextEditingController _flavor;
  late final TextEditingController _puffCount;
  late final TextEditingController _nicotineMg;
  late final TextEditingController _aliases;
  late String _category;
  late bool _requiresAttendant;

  @override
  void initState() {
    super.initState();
    final d = widget.draft;
    final defaultSku = [d.brand, d.flavor]
        .where((s) => s != null)
        .join('-')
        .toLowerCase()
        .replaceAll(' ', '-');
    _sku = TextEditingController(text: defaultSku);
    _brand = TextEditingController(text: d.brand ?? '');
    _flavor = TextEditingController(text: d.flavor ?? '');
    _puffCount = TextEditingController(
        text: d.puffCount != null ? '${d.puffCount}' : '');
    _nicotineMg = TextEditingController(
        text: d.nicotineMg != null ? '${d.nicotineMg}' : '');
    _aliases = TextEditingController();
    _category = _categories.contains(d.category) ? d.category! : 'other';
    _requiresAttendant = false;
  }

  @override
  void dispose() {
    for (final c in [_sku, _brand, _flavor, _puffCount, _nicotineMg, _aliases]) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    final aliasList = _aliases.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    widget.onCommit(CommitRequest(
      jobId: widget.draft.jobId,
      sku: _sku.text.trim(),
      brand: _brand.text.trim(),
      flavor: _flavor.text.trim(),
      category: _category,
      puffCount: int.tryParse(_puffCount.text),
      nicotineMg: int.tryParse(_nicotineMg.text),
      requiresAttendant: _requiresAttendant,
      aliases: aliasList,
    ));
  }

  Widget _signalBadge(String label, double score) {
    Color color;
    if (score >= 0.8) {
      color = Colors.green;
    } else if (score >= 0.5) {
      color = Colors.amber;
    } else {
      color = Colors.grey;
    }
    return Chip(
      label: Text('$label ${(score * 100).round()}%',
          style: TextStyle(color: color, fontSize: 11)),
      backgroundColor: color.withValues(alpha: 0.1),
      visualDensity: VisualDensity.compact,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scores = widget.draft.signalScores;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (scores != null) ...[
            Wrap(spacing: 6, children: [
              _signalBadge('UPC', scores.upc),
              _signalBadge('VLM', scores.vlm),
              _signalBadge('Embed', scores.embedding),
              _signalBadge('Dim', scores.dimension),
            ]),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _sku,
            decoration: const InputDecoration(labelText: 'SKU *'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _brand,
            decoration: const InputDecoration(labelText: 'Brand'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _flavor,
            decoration: const InputDecoration(labelText: 'Flavor / Variant'),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _category,
            decoration: const InputDecoration(labelText: 'Category'),
            items: _categories
                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                .toList(),
            onChanged: (v) => setState(() => _category = v!),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _puffCount,
            decoration: const InputDecoration(labelText: 'Puff Count'),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nicotineMg,
            decoration:
                const InputDecoration(labelText: 'Nicotine (mg, optional)'),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _aliases,
            decoration: const InputDecoration(
              labelText: 'Aliases (comma-separated)',
              hintText: 'elfie, mango elf',
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            value: _requiresAttendant,
            onChanged: (v) => setState(() => _requiresAttendant = v),
            title: const Text('Requires attendant'),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onCancel,
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _sku.text.trim().isEmpty ? null : _submit,
                  child: const Text('Commit to database'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
