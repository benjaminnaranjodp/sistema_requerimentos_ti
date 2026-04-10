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

  final List<String> _types = ['Desconecten Internet (Evaluación)', 'Añadir Nuevo Programa', 'Mantenimiento General'];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Nueva Solicitud para ${widget.module.name}'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Fecha Seleccionada'),
                subtitle: Text(DateFormat('dd/MM/yyyy').format(widget.date)),
                leading: const Icon(Icons.calendar_today, color: Colors.indigo),
                contentPadding: EdgeInsets.zero,
              ),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Tipo de Pedido'),
                items: _types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (val) => setState(() => _type = val!),
              ),
              const SizedBox(height: 10),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Hora (HH:MM)', hintText: 'Ej. 09:30'),
                initialValue: _time,
                onChanged: (val) => _time = val,
                validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Descripción / Motivo'),
                controller: _descriptionController,
                maxLines: 2,
                validator: (val) => val == null || val.isEmpty ? 'Requerido' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final request = Request(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                userId: 'current_user', // Changed on submission in screen
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
          style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
          child: const Text('Enviar Solicitud'),
        ),
      ],
    );
  }
}
