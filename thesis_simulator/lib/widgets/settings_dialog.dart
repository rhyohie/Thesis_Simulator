import 'package:flutter/material.dart';

import '../state/app_controller.dart';

Future<void> showServerDialog(BuildContext context, AppController controller) async {
  final field = TextEditingController(text: controller.baseUrl);
  final save = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Server address'),
      content: TextField(
        controller: field,
        decoration: const InputDecoration(
          labelText: 'Python service URL',
          hintText: 'http://localhost:8000',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Save and reconnect'),
        ),
      ],
    ),
  );
  final url = field.text;
  field.dispose();
  if (save == true) {
    controller.setBaseUrl(url);
  }
}
