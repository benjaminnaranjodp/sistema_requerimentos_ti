import 'package:flutter/material.dart';
import '../models/section.dart';
import '../models/module.dart';

class SectionListWidget extends StatelessWidget {
  final List<Section> sections;
  final Module? selectedModule;
  final Function(Module) onModuleSelected;

  const SectionListWidget({
    super.key,
    required this.sections,
    required this.selectedModule,
    required this.onModuleSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: sections.length,
      itemBuilder: (context, index) {
        final section = sections[index];
        return ExpansionTile(
          title: Text(section.name, style: const TextStyle(fontWeight: FontWeight.bold)),
          children: section.modules.map((module) {
            final isSelected = selectedModule?.id == module.id;
            return ListTile(
              title: Text(module.name),
              selected: isSelected,
              selectedTileColor: Colors.indigo.withAlpha(30),
              onTap: () => onModuleSelected(module),
            );
          }).toList(),
        );
      },
    );
  }
}
