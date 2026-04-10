import 'package:flutter/material.dart';
import '../models/module.dart';

class ModuleDetailWidget extends StatelessWidget {
  final Module module;
  final VoidCallback onRequestCreated;

  const ModuleDetailWidget({
    super.key,
    required this.module,
    required this.onRequestCreated,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Programas instalados en ${module.name}:',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: module.programs
              .map((p) => Chip(
                    label: Text(p),
                    backgroundColor: Colors.indigo.withAlpha(20),
                  ))
              .toList(),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onRequestCreated,
            icon: const Icon(Icons.add_task),
            label: const Text('Crear Solicitud'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}
