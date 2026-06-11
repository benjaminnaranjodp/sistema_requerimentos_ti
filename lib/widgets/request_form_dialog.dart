import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/request.dart';
import '../providers/auth_provider.dart';
import '../models/module.dart';
import '../providers/request_provider.dart';

class RequestFormDialog extends StatefulWidget {
  final Module module;
  final DateTime date;
  final Request? requestToEdit;
  final Function(Request) onSubmit;

  const RequestFormDialog({
    super.key,
    required this.module,
    required this.date,
    this.requestToEdit,
    required this.onSubmit,
  });

  @override
  State<RequestFormDialog> createState() => _RequestFormDialogState();
}

class _RequestFormDialogState extends State<RequestFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _time;
  late String _type;
  late TextEditingController _descriptionController;
  
  @override
  void initState() {
    super.initState();
    _time = widget.requestToEdit?.time ?? '09:00';
    _type = widget.requestToEdit?.type ?? 'Desconecten Internet (Evaluación)';
    
    
    if (!_types.contains(_type)) {
      _type = _types.first;
    }
    
    _descriptionController = TextEditingController(text: widget.requestToEdit?.description ?? '');
  }
  
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  final List<String> _types = [
    'Desconecten Internet (Evaluación)',
    'Añadir Nuevo Programa',
    'Mantenimiento General',
  ];

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImage = image;
        _selectedImageBytes = bytes;
      });
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isUploading = true);
    
    String? imageUrl;
    if (_selectedImage != null) {
      final reqProvider = Provider.of<RequestProvider>(context, listen: false);
      final bytes = await _selectedImage!.readAsBytes();
      imageUrl = await reqProvider.uploadImage(bytes, 'request_images');
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;

    final request = Request(
      id: widget.requestToEdit?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      userId: widget.requestToEdit?.userId ?? currentUser?.id ?? 'unknown',
      userName: widget.requestToEdit?.userName ?? currentUser?.username ?? 'Docente',
      moduleId: widget.module.id,
      date: widget.date,
      time: _time,
      type: _type,
      description: _descriptionController.text,
      status: widget.requestToEdit?.status ?? RequestStatus.pending,
      imageUrl: imageUrl ?? widget.requestToEdit?.imageUrl,
    );
    
    if (widget.requestToEdit != null) {
      await Provider.of<RequestProvider>(context, listen: false).updateRequest(request);
    }
    
    widget.onSubmit(request);
    
    if (mounted) {
      setState(() => _isUploading = false);
      Navigator.pop(context);
    }
  }

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
              widget.requestToEdit != null ? 'Editar Solicitud - ${widget.module.name}' : 'Solicitud - ${widget.module.name}',
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
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Theme.of(context).colorScheme.surface
                        : Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, 
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.indigoAccent : Colors.indigo, 
                          size: 20),
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
                const SizedBox(height: 16),
                if (_selectedImage != null && _selectedImageBytes != null)
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(_selectedImageBytes!, height: 100, width: double.infinity, fit: BoxFit.cover),
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        onPressed: () => setState(() {
                          _selectedImage = null;
                          _selectedImageBytes = null;
                        }),
                      ),
                    ],
                  )
                else
                  OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image),
                    label: const Text('Adjuntar Evidencia (Opcional)'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(40),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isUploading ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton.icon(
          onPressed: _isUploading ? null : _submit,
          icon: _isUploading 
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.send, size: 18),
          label: Text(_isUploading ? 'Enviando...' : 'Enviar'),
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
