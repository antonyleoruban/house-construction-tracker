
import 'package:flutter/material.dart';

class CustomAlertDialog extends StatelessWidget {
  final String title;
  final String content;
  final List<Widget> actions;

  const CustomAlertDialog({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Text(content),
      actions: actions,
    );
  }
}

Future<bool?> showConfirmationDialog(
  BuildContext context, {
  required String title,
  required String content,
  String confirmText = 'Confirm',
  String cancelText = 'Cancel',
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => CustomAlertDialog(
      title: title,
      content: content,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelText),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmText),
        ),
      ],
    ),
  );
}

Future<void> showInfoDialog(
  BuildContext context, {
  required String title,
  required String content,
  String dismissText = 'OK',
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => CustomAlertDialog(
      title: title,
      content: content,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(dismissText),
        ),
      ],
    ),
  );
}
