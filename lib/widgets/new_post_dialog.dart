import 'package:flutter/material.dart';

class NewPostDialog extends StatefulWidget {
  const NewPostDialog({super.key});

  @override
  State<NewPostDialog> createState() => _NewPostDialogState();
}

class _NewPostDialogState extends State<NewPostDialog> {
  final _titleController = TextEditingController();
  final _filenameController = TextEditingController();
  bool _isDraft = true;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(() {
      if (_filenameController.text.isEmpty || 
          _filenameController.text == _generateFilename(_titleController.text)) {
        _filenameController.text = _generateFilename(_titleController.text);
      }
    });
  }

  String _generateFilename(String title) {
    return title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Post'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _filenameController,
              decoration: const InputDecoration(
                labelText: 'Filename (without .md)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Save as draft'),
              value: _isDraft,
              onChanged: (value) {
                setState(() {
                  _isDraft = value;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _titleController.text.trim().isEmpty ||
                  _filenameController.text.trim().isEmpty
              ? null
              : () {
                  Navigator.pop(context, {
                    'title': _titleController.text.trim(),
                    'filename': _filenameController.text.trim(),
                    'draft': _isDraft.toString(),
                  });
                },
          child: const Text('Create'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _filenameController.dispose();
    super.dispose();
  }
}