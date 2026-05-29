import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/section.dart';
import '../models/module.dart';
import '../providers/data_provider.dart';

class SectionListWidget extends StatelessWidget {
  final List<Section> sections;
  final Module? selectedModule;
  final Function(Module) onModuleSelected;
  final bool isAdmin;

  const SectionListWidget({
    super.key,
    required this.sections,
    required this.selectedModule,
    required this.onModuleSelected,
    this.isAdmin = false,
  });

  @override
  Widget build(BuildContext context) {
    
    final List<Section> displaySections = isAdmin
        ? sections
        : sections
            .map((s) => Section(
                  id: s.id,
                  name: s.name,
                  modules: s.modules.where((m) => m.isActive).toList(),
                ))
            .where((s) => s.modules.isNotEmpty)
            .toList();

    if (displaySections.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.meeting_room, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No hay salas configuradas.',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: displaySections.length,
      itemBuilder: (context, index) {
        final section = displaySections[index];
        return ExpansionTile(
          title: Text(section.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          children: section.modules.map((module) {
            final isSelected = selectedModule?.id == module.id;
            return ListTile(
              title: Text(
                module.name,
                style: TextStyle(
                  decoration: module.isActive ? TextDecoration.none : TextDecoration.lineThrough,
                  color: module.isActive ? null : Colors.grey,
                ),
              ),
              trailing: isAdmin
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                          onPressed: () => _showEditModuleDialog(context, module),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                          onPressed: () => _showDeleteModuleDialog(context, module),
                        ),
                        Switch(
                          value: module.isActive,
                          onChanged: (val) {
                            Provider.of<DataProvider>(context, listen: false).toggleModuleStatus(module.id, module.isActive);
                          },
                          activeColor: Colors.green,
                        ),
                      ],
                    )
                  : null,
              selected: isSelected,
              selectedTileColor: Colors.indigo.withAlpha(30),
              onTap: () {
                if (module.isActive || isAdmin) {
                  onModuleSelected(module);
                }
              },
            );
          }).toList(),
        );
      },
    );
  }

  void _showEditModuleDialog(BuildContext context, Module module) {
    final nameController = TextEditingController(text: module.name);
    final sectionController = TextEditingController(text: module.sectionName);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar Sala'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nombre de la Sala'),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: sectionController,
                decoration: const InputDecoration(labelText: 'Sección o Piso'),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Provider.of<DataProvider>(context, listen: false).updateModule(
                  module.id,
                  nameController.text.trim(),
                  sectionController.text.trim(),
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

  void _showDeleteModuleDialog(BuildContext context, Module module) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Sala'),
        content: Text('¿Seguro que quieres eliminar "${module.name}" permanentemente? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Provider.of<DataProvider>(context, listen: false).deleteModule(module.id);
              Navigator.pop(ctx);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
