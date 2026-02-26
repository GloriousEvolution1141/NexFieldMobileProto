import 'package:flutter/material.dart';

class SincronizacionDialog extends StatefulWidget {
  final Future<void> Function(Function(String) onProgress) tareaSincronizacion;

  const SincronizacionDialog({super.key, required this.tareaSincronizacion});

  @override
  State<SincronizacionDialog> createState() => _SincronizacionDialogState();
}

class _SincronizacionDialogState extends State<SincronizacionDialog> {
  String _mensaje = "Iniciando subida...";

  @override
  void initState() {
    super.initState();
    _iniciar();
  }

  Future<void> _iniciar() async {
    await widget.tareaSincronizacion((msg) {
      if (mounted) setState(() => _mensaje = msg);
    });
    if (mounted) Navigator.pop(context); 
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Completando Suministro'),
      content: Row(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(width: 20),
          Expanded(child: Text(_mensaje)),
        ],
      )
    );
  }
}
