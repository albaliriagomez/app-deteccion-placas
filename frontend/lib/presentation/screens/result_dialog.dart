import 'package:flutter/material.dart';

class ResultDialog extends StatelessWidget {
  final String plate;
  final String base64Image;
  final Function(String, String) onConfirm;
  const ResultDialog({super.key, required this.plate, required this.base64Image, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Placa detectada'),
      content: Text('Placa: $plate'),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cerrar')),
        ElevatedButton(onPressed: () {
          onConfirm(plate, base64Image);
          Navigator.of(context).pop();
        }, child: const Text('Confirmar')),
      ],
    );
  }
}
