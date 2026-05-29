import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/module.dart';
import '../providers/auth_provider.dart';
import '../providers/data_provider.dart';

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
    final authProvider = Provider.of<AuthProvider>(context);
    final isTI = authProvider.isAdmin; 
    final isDocente = !isTI;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Programas instalados en ${module.name}:',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            if (isTI)
              IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.indigo, size: 28),
                tooltip: 'Añadir Programa',
                onPressed: () => _showAddProgramDialog(context),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: module.programs.isEmpty
              ? [const Text('No hay programas registrados.', style: TextStyle(color: Colors.grey))]
              : module.programs
                  .map((p) => isTI
                      ? InputChip(
                          label: Text(p),
                          backgroundColor: Colors.indigo.withAlpha(20),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Eliminar Programa'),
                                content: Text('¿Seguro que quieres eliminar "$p" de esta sala?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                    onPressed: () {
                                      Provider.of<DataProvider>(context, listen: false).removeProgramFromModule(module.id, p);
                                      Navigator.pop(ctx);
                                    },
                                    child: const Text('Eliminar'),
                                  ),
                                ],
                              ),
                            );
                          },
                          onPressed: () => _showEditProgramDialog(context, p),
                        )
                      : Chip(
                          label: Text(p),
                          backgroundColor: Colors.indigo.withAlpha(20),
                        ))
                  .toList(),
        ),
        const Spacer(),
        if (isDocente)
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

  void _showAddProgramDialog(BuildContext context) {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Añadir Programa'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Nombre del Programa (ej. AutoCAD)'),
            validator: (v) => v!.isEmpty ? 'Requerido' : null,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Provider.of<DataProvider>(context, listen: false).addProgramToModule(
                  module.id,
                  controller.text.trim(),
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Añadir'),
          ),
        ],
      ),
    );
  }

  void _showEditProgramDialog(BuildContext context, String currentName) {
    final controller = TextEditingController(text: currentName);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar Programa'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Nombre del Programa'),
            validator: (v) => v!.isEmpty ? 'Requerido' : null,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Provider.of<DataProvider>(context, listen: false).updateProgramInModule(
                  module.id,
                  currentName,
                  controller.text.trim(),
                );
                Navigator.pop(ctx);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
