import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/request.dart';
import '../models/module.dart';

class RequestFormDialog extends StatefulWidget {
  final Module module;
  final DateTime date;
  final Function(Request) onSubmit;

  const RequestFormDialog({
    super.key,
    required this.module,
    required this.date,
    required this.onSubmit,
  });

  @override
  State<RequestFormDialog> createState() => _RequestFormDialogState();
}

class _RequestFormDialogState extends State<RequestFormDialog> {
  final _formKey = GlobalKey<FormState>();
  String _time = '09:00';
  String _type = 'Desconecten Internet (Evaluación)';
  final _descriptionController = TextEditingController();

  final List<String> _types = [
    'Desconecten Internet (Evaluación)',
    'Añadir Nuevo Programa',
    'Mantenimiento General',
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.add_task, color: Colors.indigo),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Solicitud - ${widget.module.name}',
              style: TextStyle(fontSize: isMobile ? 16 : 20),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 40,
        vertical: 24,
      ),
      content: SizedBox(
        width: isMobile ? double.maxFinite : 450,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.indigo, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        DateFormat('dd/MM/yyyy').format(widget.date),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _type,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Tipo de Pedido',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                  items: _types
                      .map((t) => DropdownMenuItem(value: t, child: Text(t, overflow: TextOverflow.ellipsis)))
                      .toList(),
                  onChanged: (val) => setState(() => _type = val!),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Hora (HH:MM)',
                    hintText: 'Ej. 09:30',
                    prefixIcon: const Icon(Icons.access_time),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  initialValue: _time,
                  onChanged: (val) => _time = val,
                  validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Descripción / Motivo',
                    prefixIcon: const Icon(Icons.description),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    alignLabelWithHint: true,
                  ),
                  controller: _descriptionController,
                  maxLines: 3,
                  validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final request = Request(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                userId: 'current_user',
                moduleId: widget.module.id,
                date: widget.date,
                time: _time,
                type: _type,
                description: _descriptionController.text,
              );
              widget.onSubmit(request);
              Navigator.pop(context);
            }
          },
          icon: const Icon(Icons.send, size: 18),
          label: const Text('Enviar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }
}
