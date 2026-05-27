import 'package:flutter/material.dart';
import '../../api/types/vision_types.dart';

class DeduceResultTile extends StatelessWidget {
  final DeduceCandidate candidate;

  const DeduceResultTile({super.key, required this.candidate});

  Color _confidenceColor(double c) {
    if (c >= 0.85) return Colors.green;
    if (c >= 0.60) return Colors.amber;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final pct = (candidate.confidence * 100).toStringAsFixed(0);
    final color = _confidenceColor(candidate.confidence);
    return ListTile(
      title: Text(candidate.sku,
          style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (candidate.brand != null || candidate.flavor != null)
            Text('${candidate.brand ?? ''} ${candidate.flavor ?? ''}'.trim()),
          Text(candidate.matchReason,
              style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$pct%',
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(width: 6),
          Icon(Icons.circle, color: color, size: 10),
        ],
      ),
      isThreeLine: true,
    );
  }
}
