import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/request_provider.dart';
import '../models/request.dart';

class AdminRequestList extends StatelessWidget {
  const AdminRequestList({super.key});

  @override
  Widget build(BuildContext context) {
    final requestProvider = Provider.of<RequestProvider>(context);
    final allRequests = requestProvider.requests;

    final pendingRequests = allRequests.where((r) => r.status == RequestStatus.pending).toList();
    final historyRequests = allRequests.where((r) => r.status != RequestStatus.pending).toList();

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Theme.of(context).cardColor,
            child: TabBar(
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Theme.of(context).colorScheme.primary,
              tabs: const [
                Tab(text: 'Pendientes'),
                Tab(text: 'Historial'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildList(pendingRequests, 'No hay solicitudes pendientes.'),
                _buildList(historyRequests, 'No hay historial de solicitudes.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<Request> requests, String emptyMessage) {
    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              emptyMessage,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        return _buildRequestCard(context, requests[index]);
      },
    );
  }

  Widget _buildRequestCard(BuildContext context, Request request) {
    final isPending = request.status == RequestStatus.pending;

    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (request.status) {
      case RequestStatus.pending:
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        statusText = 'Pendiente';
        break;
      case RequestStatus.accepted:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Aceptada';
        break;
      case RequestStatus.rejected:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Rechazada';
        break;
      case RequestStatus.offlinePending:
        statusColor = Colors.blueGrey;
        statusIcon = Icons.cloud_off;
        statusText = 'Pendiente de envío';
        break;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withAlpha(60)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            Row(
              children: [
                Expanded(
                  child: Text(
                    request.type,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            
            _buildInfoRow(Icons.person, 'Solicitante: ${request.userName.isNotEmpty ? request.userName : request.userId}'),
            const SizedBox(height: 4),
            _buildInfoRow(Icons.meeting_room, 'Sala: ${request.moduleId}'),
            const SizedBox(height: 4),
            _buildInfoRow(Icons.calendar_today, 'Fecha: ${DateFormat('dd/MM/yyyy').format(request.date)} a las ${request.time}'),
            const SizedBox(height: 6),
            Text(
              request.description,
              style: const TextStyle(fontSize: 13),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            
            if (request.imageUrl != null) ...[
              const SizedBox(height: 10),
              const Text('Evidencia del Docente:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(request.imageUrl!, height: 120, width: double.infinity, fit: BoxFit.cover),
              ),
            ],

            if (request.adminComment != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.comment, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        request.adminComment!,
                        style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (request.adminImageUrl != null) ...[
              const SizedBox(height: 10),
              const Text('Evidencia TI:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(request.adminImageUrl!, height: 120, width: double.infinity, fit: BoxFit.cover),
              ),
            ],

            
            if (isPending) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _showActionDialog(context, request, RequestStatus.rejected),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Rechazar', style: TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showActionDialog(context, request, RequestStatus.accepted),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Aceptar', style: TextStyle(fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 15, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _showActionDialog(BuildContext context, Request request, RequestStatus status) {
    final controller = TextEditingController();
    bool isUploading = false;
    XFile? selectedImage;
    Uint8List? selectedImageBytes;
    final ImagePicker picker = ImagePicker();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(
                  status == RequestStatus.accepted ? Icons.check_circle : Icons.cancel,
                  color: status == RequestStatus.accepted ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(status == RequestStatus.accepted ? 'Aceptar Solicitud' : 'Rechazar Solicitud'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: 'Comentario (Opcional)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  if (selectedImage != null && selectedImageBytes != null)
                    Stack(
                      alignment: Alignment.topRight,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(selectedImageBytes!, height: 100, width: double.infinity, fit: BoxFit.cover),
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          onPressed: () => setState(() {
                            selectedImage = null;
                            selectedImageBytes = null;
                          }),
                        ),
                      ],
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: () async {
                        final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                        if (image != null) {
                          final bytes = await image.readAsBytes();
                          setState(() {
                            selectedImage = image;
                            selectedImageBytes = bytes;
                          });
                        }
                      },
                      icon: const Icon(Icons.image),
                      label: const Text('Adjuntar Evidencia'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(40),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isUploading ? null : () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: isUploading ? null : () async {
                  setState(() => isUploading = true);
                  String? adminImageUrl;
                  
                  if (selectedImage != null) {
                    final reqProvider = Provider.of<RequestProvider>(context, listen: false);
                    final bytes = await selectedImage!.readAsBytes();
                    adminImageUrl = await reqProvider.uploadImage(bytes, 'admin_images');
                  }

                  if (context.mounted) {
                    await Provider.of<RequestProvider>(context, listen: false).updateRequestStatus(
                      request.id,
                      status,
                      comment: controller.text.isNotEmpty ? controller.text : null,
                      adminImageUrl: adminImageUrl,
                    );
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: status == RequestStatus.accepted ? Colors.green : Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: isUploading 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Confirmar'),
              ),
            ],
          );
        }
      ),
    );
  }
}
