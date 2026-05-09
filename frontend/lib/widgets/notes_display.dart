import 'package:flutter/material.dart';
import '../models/note.dart';

class NotesDisplay extends StatelessWidget {
  final List<Note>? notes;
  final bool showTimestamp;
  final bool showAuthor;

  const NotesDisplay({
    Key? key,
    this.notes,
    this.showTimestamp = true,
    this.showAuthor = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (notes == null || notes!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notes History',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...notes!.map((note) => _buildNoteItem(context, note)).toList(),
      ],
    );
  }

  Widget _buildNoteItem(BuildContext context, Note note) {
    final isParishioner = note.author == 'parishioner';
    final authorLabel = isParishioner ? 'Parishioner' : 'Admin';
    final backgroundColor = isParishioner
        ? Colors.blue.shade50
        : Colors.grey.shade200;
    final borderColor = isParishioner
        ? Colors.blue.shade200
        : Colors.grey.shade400;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (showAuthor)
                Text(
                  authorLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isParishioner ? Colors.blue : Colors.black87,
                  ),
                ),
              if (showAuthor && showTimestamp) const Spacer(),
              if (showTimestamp && note.timestamp != null)
                Text(
                  _formatTimestamp(note.timestamp!),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
          if (note.content != null) ...[
            const SizedBox(height: 4),
            Text(
              note.content!,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return timestamp;
    }
  }
}
